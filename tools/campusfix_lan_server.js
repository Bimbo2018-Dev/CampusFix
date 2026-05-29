const fs = require('fs');
const http = require('http');
const path = require('path');
const zlib = require('zlib');

const root = path.join(process.cwd(), 'build', 'web');
const host = process.env.CAMPUSFIX_HOST || '0.0.0.0';
const port = Number(process.env.CAMPUSFIX_PORT || 8791);

const types = {
  '.apk': 'application/vnd.android.package-archive',
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

const compressedTypes = new Set([
  '.css',
  '.html',
  '.js',
  '.json',
  '.mjs',
  '.svg',
  '.wasm',
]);

function buildVersionPayload() {
  const watchedFiles = ['index.html', 'flutter_bootstrap.js', 'main.dart.js'];
  const entries = watchedFiles.map((fileName) => {
    const filePath = path.join(root, fileName);
    const stat = fs.statSync(filePath);
    return {
      file: fileName,
      size: stat.size,
      modified: stat.mtimeMs,
    };
  });

  return {
    app: 'CampusFix',
    generatedAt: Date.now(),
    signature: entries
      .map((entry) => `${entry.file}:${entry.size}:${entry.modified}`)
      .join('|'),
    entries,
  };
}

function resolveRequestPath(url) {
  const rawPath = decodeURIComponent(url.split('?')[0]);
  const target = path.join(root, rawPath === '/' ? 'index.html' : rawPath);
  const normalized = path.normalize(target);
  if (!normalized.startsWith(root)) {
    return null;
  }
  return normalized;
}

function cacheHeader(filePath) {
  const name = path.basename(filePath);
  if (
    name === 'index.html' ||
    name === 'flutter_bootstrap.js' ||
    name === 'main.dart.js' ||
    name === 'campusfix_android_version.json' ||
    name === 'CampusFix.apk'
  ) {
    return 'no-store';
  }
  return 'public, max-age=3600';
}

function etagFor(stat) {
  return `"${stat.size}-${Number(stat.mtimeMs).toString(36)}"`;
}

const server = http.createServer((request, response) => {
  const requestPath = decodeURIComponent(request.url.split('?')[0]);
  if (requestPath === '/__campusfix_version.json') {
    try {
      const payload = JSON.stringify(buildVersionPayload());
      response.writeHead(200, {
        'Cache-Control': 'no-store',
        'Content-Length': Buffer.byteLength(payload),
        'Content-Type': 'application/json; charset=utf-8',
      });
      response.end(payload);
    } catch (error) {
      response.writeHead(503, {
        'Cache-Control': 'no-store',
        'Content-Type': 'application/json; charset=utf-8',
      });
      response.end(JSON.stringify({ error: 'Version unavailable' }));
    }
    return;
  }

  let filePath = resolveRequestPath(request.url);
  if (filePath === null) {
    response.writeHead(403);
    response.end('Forbidden');
    return;
  }

  fs.stat(filePath, (statError, stat) => {
    if (statError || !stat.isFile()) {
      filePath = path.join(root, 'index.html');
      stat = fs.statSync(filePath);
    }

    const ext = path.extname(filePath);
    const etag = etagFor(stat);
    const headers = {
      'Cache-Control': cacheHeader(filePath),
      'Content-Type': types[ext] || 'application/octet-stream',
      ETag: etag,
    };

    if (request.headers['if-none-match'] === etag) {
      response.writeHead(304, headers);
      response.end();
      return;
    }

    if (request.method === 'HEAD') {
      headers['Content-Length'] = stat.size;
      response.writeHead(200, headers);
      response.end();
      return;
    }

    const acceptsGzip = request.headers['accept-encoding']?.includes('gzip');
    if (acceptsGzip && compressedTypes.has(ext)) {
      response.writeHead(200, {
        ...headers,
        'Content-Encoding': 'gzip',
        Vary: 'Accept-Encoding',
      });
      fs.createReadStream(filePath).pipe(zlib.createGzip()).pipe(response);
      return;
    }

    headers['Content-Length'] = stat.size;
    response.writeHead(200, headers);
    fs.createReadStream(filePath).pipe(response);
  });
});

server.listen(port, host, () => {
  console.log(`CampusFix LAN server http://${host}:${port}`);
});
