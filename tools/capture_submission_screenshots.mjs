import { mkdir, rm, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { resolve } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';

class CdpConnection {
  constructor(url) {
    this.nextId = 1;
    this.pending = new Map();
    this.ws = new WebSocket(url);
    this.ready = new Promise((resolveReady, reject) => {
      this.ws.addEventListener('open', resolveReady, { once: true });
      this.ws.addEventListener('error', reject, { once: true });
    });
    this.ws.addEventListener('message', (event) => {
      const message = JSON.parse(event.data);
      if (!message.id) return;
      const pending = this.pending.get(message.id);
      if (!pending) return;
      this.pending.delete(message.id);
      if (message.error) {
        pending.reject(new Error(message.error.message));
      } else {
        pending.resolve(message.result ?? {});
      }
    });
  }

  send(method, params = {}, sessionId = undefined) {
    const id = this.nextId++;
    const payload = { id, method, params };
    if (sessionId) payload.sessionId = sessionId;
    const promise = new Promise((resolveResult, reject) => {
      this.pending.set(id, { resolve: resolveResult, reject });
    });
    this.ws.send(JSON.stringify(payload));
    return promise;
  }

  close() {
    this.ws.close();
  }
}

const chromePath = process.argv[2];
const outputDir = resolve(process.argv[3]);
const appUrl = process.argv[4] ?? 'http://127.0.0.1:8792';

if (!chromePath || !outputDir) {
  console.error('Usage: node tools/capture_submission_screenshots.mjs <chrome-path> <output-dir> [app-url]');
  process.exit(1);
}

const port = 9224 + Math.floor(Math.random() * 500);
const userDataDir = resolve(`${outputDir.replace(/[\\/]+$/, '')}/chrome-profile`);

await rm(outputDir, { recursive: true, force: true });
await mkdir(outputDir, { recursive: true });

const chrome = spawn(chromePath, [
  '--headless=new',
  `--remote-debugging-port=${port}`,
  `--user-data-dir=${userDataDir}`,
  '--window-size=1440,900',
  '--disable-gpu',
  '--enable-unsafe-swiftshader',
  '--ignore-gpu-blocklist',
  '--disable-dev-shm-usage',
  '--no-first-run',
  '--no-default-browser-check',
  'about:blank',
], {
  stdio: 'ignore',
});
const chromeExited = new Promise((resolveExit) => chrome.once('exit', resolveExit));

let browser;
try {
  const version = await waitForJson(`http://127.0.0.1:${port}/json/version`, 20000);
  browser = new CdpConnection(version.webSocketDebuggerUrl);
  await browser.ready;

  const { targetId } = await browser.send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await browser.send('Target.attachToTarget', {
    targetId,
    flatten: true,
  });

  await setupPage(browser, sessionId);

  await browser.send('Page.navigate', { url: `${appUrl}/?shot=welcome` }, sessionId);
  await sleep(14000);
  await screenshot(browser, sessionId, '01_welcome_install_screen.png');

  await click(browser, sessionId, 390, 620);
  await sleep(3500);
  await screenshot(browser, sessionId, '02_student_login_screen.png');

  await fillLogin(browser, sessionId, 'student@campusfix.app', 'student123');
  await sleep(6500);
  await screenshot(browser, sessionId, '03_student_dashboard.png');

  await click(browser, sessionId, 130, 289);
  await sleep(2500);
  await screenshot(browser, sessionId, '04_add_report_screen.png');

  await browser.send('Page.navigate', { url: `${appUrl}/?shot=admin` }, sessionId);
  await sleep(10000);
  await click(browser, sessionId, 1055, 620);
  await sleep(3000);
  await fillLogin(browser, sessionId, 'admin@campusfix.app', 'admin123');
  await sleep(7500);
  await screenshot(browser, sessionId, '05_admin_dashboard.png');

  await click(browser, sessionId, 132, 234);
  await sleep(3500);
  await screenshot(browser, sessionId, '06_reports_list.png');

  await browser.send('Target.closeTarget', { targetId });
} finally {
  try {
    await browser?.close();
  } catch {
    // Browser may already be gone.
  }
  chrome.kill();
  await Promise.race([chromeExited, sleep(3000)]);
  await rm(userDataDir, { recursive: true, force: true });
}

async function setupPage(browser, sessionId) {
  await browser.send('Page.enable', {}, sessionId);
  await browser.send('Runtime.enable', {}, sessionId);
  await browser.send('Network.enable', {}, sessionId);
  await browser.send('Emulation.setDeviceMetricsOverride', {
    width: 1440,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  }, sessionId);
  await browser.send('Page.addScriptToEvaluateOnNewDocument', {
    source: `
      try {
        localStorage.removeItem('flutter.campusfix.session.v1');
        localStorage.removeItem('campusfix.session.v1');
      } catch (error) {}
    `,
  }, sessionId);
}

async function fillLogin(browser, sessionId, email, password) {
  await click(browser, sessionId, 715, 430);
  await typeText(browser, sessionId, email);
  await click(browser, sessionId, 715, 520);
  await typeText(browser, sessionId, password);
  await click(browser, sessionId, 720, 615);
}

async function screenshot(browser, sessionId, name) {
  const image = await browser.send('Page.captureScreenshot', {
    format: 'png',
    fromSurface: true,
    captureBeyondViewport: false,
  }, sessionId);
  await writeFile(`${outputDir}/${name}`, Buffer.from(image.data, 'base64'));
  console.log(`Captured ${name}`);
}

async function click(browser, sessionId, x, y) {
  await browser.send('Input.dispatchMouseEvent', {
    type: 'mouseMoved',
    x,
    y,
    button: 'none',
  }, sessionId);
  await browser.send('Input.dispatchMouseEvent', {
    type: 'mousePressed',
    x,
    y,
    button: 'left',
    clickCount: 1,
  }, sessionId);
  await browser.send('Input.dispatchMouseEvent', {
    type: 'mouseReleased',
    x,
    y,
    button: 'left',
    clickCount: 1,
  }, sessionId);
}

async function typeText(browser, sessionId, text) {
  await browser.send('Input.dispatchKeyEvent', {
    type: 'keyDown',
    windowsVirtualKeyCode: 65,
    modifiers: 2,
  }, sessionId);
  await browser.send('Input.dispatchKeyEvent', {
    type: 'keyUp',
    windowsVirtualKeyCode: 65,
    modifiers: 2,
  }, sessionId);
  await browser.send('Input.dispatchKeyEvent', {
    type: 'keyDown',
    windowsVirtualKeyCode: 8,
  }, sessionId);
  await browser.send('Input.dispatchKeyEvent', {
    type: 'keyUp',
    windowsVirtualKeyCode: 8,
  }, sessionId);
  await browser.send('Input.insertText', { text }, sessionId);
}

async function waitForJson(url, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let lastError;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) return await response.json();
    } catch (error) {
      lastError = error;
    }
    await sleep(250);
  }
  throw lastError ?? new Error(`Timed out waiting for ${url}`);
}
