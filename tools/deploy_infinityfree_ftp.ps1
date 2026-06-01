param(
  [string]$FtpHost = "ftpupload.net",
  [int]$FtpPort = 21,
  [Parameter(Mandatory = $true)]
  [string]$FtpUsername,
  [Parameter(Mandatory = $true)]
  [string]$FtpPassword,
  [Parameter(Mandatory = $true)]
  [string]$SiteUrl,
  [string]$RemoteRoot = "/htdocs",
  [string]$BackendZip = "",
  [string]$SqlFile = "",
  [string]$Token = "",
  [int]$ChunkSizeBytes = 4194304,
  [string]$ChallengeCookie = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot "build\infinityfree"

if ([string]::IsNullOrWhiteSpace($BackendZip)) {
  $BackendZip = Join-Path $buildRoot "campusfix-infinityfree-backend.zip"
}
if ([string]::IsNullOrWhiteSpace($SqlFile)) {
  $SqlFile = Join-Path $buildRoot "database\campusfix_mysql_export.sql"
}
if ([string]::IsNullOrWhiteSpace($Token)) {
  $bytes = New-Object byte[] 24
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $Token = [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

$BackendZip = (Resolve-Path -LiteralPath $BackendZip).Path
$SqlFile = (Resolve-Path -LiteralPath $SqlFile).Path
$deployerPath = Join-Path $buildRoot "_campusfix_deploy.php"
$deployId = "deploy" + (Get-Date -Format "yyyyMMddHHmmss")
$remoteZipName = "_campusfix_backend_$deployId.zip"
$remoteChunkPrefix = "$remoteZipName.part"
$remoteSqlName = "_campusfix_import.sql"
$remoteDeployerName = "_campusfix_deploy.php"
$chunkRoot = Join-Path $buildRoot "ftp_chunks"

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
  $encoding = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllLines($Path, $Lines, $encoding)
}

function New-FtpUri([string]$RemotePath) {
  $trimmed = $RemotePath.Trim("/")
  $escaped = ($trimmed -split "/" | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join "/"
  return "ftp://${FtpHost}:$FtpPort/$escaped"
}

function Invoke-FtpUpload([string]$LocalPath, [string]$RemotePath) {
  $uri = New-FtpUri $RemotePath
  $request = [System.Net.FtpWebRequest]::Create($uri)
  $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
  $request.Credentials = New-Object System.Net.NetworkCredential($FtpUsername, $FtpPassword)
  $request.UseBinary = $true
  $request.UsePassive = $true
  $request.KeepAlive = $false

  $bytes = [System.IO.File]::ReadAllBytes($LocalPath)
  $request.ContentLength = $bytes.Length
  $stream = $request.GetRequestStream()
  try {
    $stream.Write($bytes, 0, $bytes.Length)
  } finally {
    $stream.Dispose()
  }

  $response = $request.GetResponse()
  try {
    Write-Host "Uploaded $RemotePath"
  } finally {
    $response.Dispose()
  }
}

function Split-FileForUpload([string]$Path) {
  if (Test-Path $chunkRoot) {
    Remove-Item -LiteralPath $chunkRoot -Recurse -Force
  }
  New-Item -ItemType Directory -Path $chunkRoot -Force | Out-Null

  $buffer = New-Object byte[] $ChunkSizeBytes
  $chunks = New-Object System.Collections.Generic.List[string]
  $inputStream = [System.IO.File]::OpenRead($Path)
  try {
    $index = 0
    while (($read = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
      $chunkPath = Join-Path $chunkRoot ("{0}{1:D3}" -f $remoteChunkPrefix, $index)
      $outputStream = [System.IO.File]::Create($chunkPath)
      try {
        $outputStream.Write($buffer, 0, $read)
      } finally {
        $outputStream.Dispose()
      }
      $chunks.Add($chunkPath)
      $index++
    }
  } finally {
    $inputStream.Dispose()
  }

  return $chunks
}

function Invoke-Deployer([string]$Action) {
  $base = $SiteUrl.TrimEnd("/")
  $uri = "$base/$remoteDeployerName?action=$Action&token=$([System.Uri]::EscapeDataString($Token))"
  Write-Host "Running remote action: $Action"
  $requestArgs = @{
    Uri = $uri
    UseBasicParsing = $true
    TimeoutSec = 300
  }
  if (-not [string]::IsNullOrWhiteSpace($ChallengeCookie)) {
    $requestArgs.Headers = @{ Cookie = "__test=$ChallengeCookie" }
  }
  $response = Invoke-WebRequest @requestArgs
  Write-Host $response.Content
  return $response.Content | ConvertFrom-Json
}

$deployer = @'
<?php
declare(strict_types=1);

const CAMPUSFIX_TOKEN = '__TOKEN__';
const CAMPUSFIX_ZIP = '__ZIP__';
const CAMPUSFIX_CHUNK_PREFIX = '__CHUNK_PREFIX__';
const CAMPUSFIX_SQL = '__SQL__';

header('Content-Type: application/json');
set_time_limit(300);

function respond(array $payload, int $status = 200): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_PRETTY_PRINT);
    exit;
}

function env_value(array $env, string $key, ?string $default = null): ?string
{
    if (! array_key_exists($key, $env)) {
        return $default;
    }

    return trim((string) $env[$key], "\"'");
}

function build_zip_from_chunks(string $zipPath): int
{
    $pattern = __DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_CHUNK_PREFIX . '*';
    $chunks = glob($pattern);
    if (! is_array($chunks) || count($chunks) === 0) {
        respond(['ok' => false, 'error' => 'Backend zip chunks are missing.'], 404);
    }

    sort($chunks, SORT_NATURAL);
    $output = fopen($zipPath, 'wb');
    if ($output === false) {
        respond(['ok' => false, 'error' => 'Could not create backend zip from chunks.'], 500);
    }

    foreach ($chunks as $chunk) {
        $input = fopen($chunk, 'rb');
        if ($input === false) {
            fclose($output);
            respond(['ok' => false, 'error' => 'Could not read chunk: ' . basename($chunk)], 500);
        }
        stream_copy_to_stream($input, $output);
        fclose($input);
    }

    fclose($output);
    return count($chunks);
}

function ensure_campusfix_schema(mysqli $mysqli): array
{
    $changes = [];

    $hasUserActive = $mysqli->query("SHOW COLUMNS FROM `users` LIKE 'is_active'");
    if ($hasUserActive && $hasUserActive->num_rows === 0) {
        if (! $mysqli->query("ALTER TABLE `users` ADD COLUMN `is_active` tinyint(1) NOT NULL DEFAULT 1 AFTER `avatar_text`")) {
            respond(['ok' => false, 'error' => 'Schema patch failed: ' . $mysqli->error], 500);
        }
        $changes[] = 'users.is_active';
    }

    $hasResolvedImage = $mysqli->query("SHOW COLUMNS FROM `reports` LIKE 'resolved_image_path'");
    if ($hasResolvedImage && $hasResolvedImage->num_rows === 0) {
        if (! $mysqli->query("ALTER TABLE `reports` ADD COLUMN `resolved_image_path` longtext NULL AFTER `image_path`")) {
            respond(['ok' => false, 'error' => 'Schema patch failed: ' . $mysqli->error], 500);
        }
        $changes[] = 'reports.resolved_image_path';
    }

    $mysqli->query("UPDATE `users` SET `is_active` = 1 WHERE `is_active` IS NULL OR `is_active` = 0");

    return $changes;
}

$token = $_GET['token'] ?? '';
if (! hash_equals(CAMPUSFIX_TOKEN, $token)) {
    respond(['ok' => false, 'error' => 'Forbidden'], 403);
}

$action = $_GET['action'] ?? 'status';

try {
    if ($action === 'status') {
        respond([
            'ok' => true,
            'php' => PHP_VERSION,
            'zip' => class_exists(ZipArchive::class),
            'dir' => __DIR__,
        ]);
    }

    if ($action === 'extract') {
        if (! class_exists(ZipArchive::class)) {
            respond(['ok' => false, 'error' => 'PHP ZipArchive extension is not enabled.'], 500);
        }

        $zipPath = __DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_ZIP;
        if (! is_file($zipPath)) {
            $chunkCount = build_zip_from_chunks($zipPath);
        } else {
            $chunkCount = 0;
        }

        $zip = new ZipArchive();
        $opened = $zip->open($zipPath);
        if ($opened !== true) {
            respond(['ok' => false, 'error' => 'Could not open backend zip.', 'code' => $opened], 500);
        }

        $zip->extractTo(__DIR__);
        $fileCount = $zip->numFiles;
        $zip->close();

        respond(['ok' => true, 'action' => 'extract', 'files' => $fileCount, 'chunks' => $chunkCount]);
    }

    if ($action === 'import') {
        $envPath = __DIR__ . DIRECTORY_SEPARATOR . '.env';
        $sqlPath = __DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_SQL;

        if (! is_file($envPath)) {
            respond(['ok' => false, 'error' => '.env is missing. Run extract first.'], 404);
        }
        if (! is_file($sqlPath)) {
            respond(['ok' => false, 'error' => 'SQL import file is missing.'], 404);
        }

        $env = parse_ini_file($envPath, false, INI_SCANNER_RAW);
        if ($env === false) {
            respond(['ok' => false, 'error' => 'Could not parse .env.'], 500);
        }

        $host = env_value($env, 'DB_HOST', 'localhost');
        $port = (int) env_value($env, 'DB_PORT', '3306');
        $database = env_value($env, 'DB_DATABASE', '');
        $username = env_value($env, 'DB_USERNAME', '');
        $password = env_value($env, 'DB_PASSWORD', '');

        mysqli_report(MYSQLI_REPORT_OFF);
        $mysqli = @new mysqli($host, $username, $password, $database, $port);
        if ($mysqli->connect_errno) {
            respond(['ok' => false, 'error' => 'MySQL connection failed: ' . $mysqli->connect_error], 500);
        }
        $mysqli->set_charset('utf8mb4');

        $sql = (string) file_get_contents($sqlPath);
        $sql = preg_replace('/^\s*CREATE DATABASE\b.*?;\s*$/mi', '', $sql);
        $sql = preg_replace('/^\s*USE\s+`?[^`;]+`?\s*;\s*$/mi', '', $sql);
        $sql = preg_replace('/^\s*LOCK TABLES\b.*?;\s*$/mi', '', $sql);
        $sql = preg_replace('/^\s*UNLOCK TABLES\s*;\s*$/mi', '', $sql);
        $sql = str_replace('`campusfix_api`', '`' . str_replace('`', '``', $database) . '`', $sql);

        if (! $mysqli->multi_query($sql)) {
            respond(['ok' => false, 'error' => 'Import failed: ' . $mysqli->error], 500);
        }

        $resultCount = 0;
        do {
            if ($result = $mysqli->store_result()) {
                $result->free();
            }
            $resultCount++;
            if ($mysqli->errno) {
                respond(['ok' => false, 'error' => 'Import failed: ' . $mysqli->error], 500);
            }
        } while ($mysqli->more_results() && $mysqli->next_result());

        $schemaChanges = ensure_campusfix_schema($mysqli);

        respond(['ok' => true, 'action' => 'import', 'statements' => $resultCount, 'schemaChanges' => $schemaChanges]);
    }

    if ($action === 'cleanup') {
        @unlink(__DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_ZIP);
        @unlink(__DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_SQL);
        $chunks = glob(__DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_CHUNK_PREFIX . '*');
        if (is_array($chunks)) {
            foreach ($chunks as $chunk) {
                @unlink($chunk);
            }
        }
        $items = scandir(__DIR__);
        if (is_array($items)) {
            foreach ($items as $item) {
                if (strpos($item, '\\') !== false) {
                    @unlink(__DIR__ . DIRECTORY_SEPARATOR . $item);
                }
            }
        }
        @unlink(__FILE__);
        respond(['ok' => true, 'action' => 'cleanup']);
    }

    respond(['ok' => false, 'error' => 'Unknown action.'], 400);
} catch (Throwable $e) {
    respond(['ok' => false, 'error' => $e->getMessage()], 500);
}
'@

$deployer = $deployer.Replace("__TOKEN__", $Token)
$deployer = $deployer.Replace("__ZIP__", $remoteZipName)
$deployer = $deployer.Replace("__CHUNK_PREFIX__", $remoteChunkPrefix)
$deployer = $deployer.Replace("__SQL__", $remoteSqlName)
Write-Utf8NoBom $deployerPath ($deployer -split "`r?`n")

Invoke-FtpUpload $deployerPath "$RemoteRoot/$remoteDeployerName"
$chunkPaths = Split-FileForUpload $BackendZip
foreach ($chunkPath in $chunkPaths) {
  Invoke-FtpUpload $chunkPath "$RemoteRoot/$(Split-Path -Leaf $chunkPath)"
}
Invoke-FtpUpload $SqlFile "$RemoteRoot/$remoteSqlName"

Invoke-Deployer "status" | Out-Null
Invoke-Deployer "extract" | Out-Null
Invoke-Deployer "import" | Out-Null
Invoke-Deployer "cleanup" | Out-Null

Write-Host ""
Write-Host "InfinityFree backend deployed. Test:"
Write-Host "$($SiteUrl.TrimEnd('/'))/api/health"
