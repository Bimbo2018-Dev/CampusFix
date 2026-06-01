param(
  [string]$FtpHost = "ftpupload.net",
  [int]$FtpPort = 21,
  [Parameter(Mandatory = $true)]
  [string]$FtpUsername,
  [Parameter(Mandatory = $true)]
  [string]$FtpPassword,
  [Parameter(Mandatory = $true)]
  [string]$SiteUrl,
  [Parameter(Mandatory = $true)]
  [string]$LocalFile,
  [Parameter(Mandatory = $true)]
  [string]$RemotePath,
  [string]$MetadataFile = "",
  [string]$MetadataRemotePath = "",
  [string]$RemoteRoot = "/htdocs",
  [string]$Token = "",
  [string]$ChallengeCookie = "",
  [int]$ChunkSizeBytes = 4194304
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Token)) {
  $bytes = New-Object byte[] 24
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $Token = [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

$LocalFile = (Resolve-Path -LiteralPath $LocalFile).Path
if (-not [string]::IsNullOrWhiteSpace($MetadataFile)) {
  $MetadataFile = (Resolve-Path -LiteralPath $MetadataFile).Path
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$workRoot = Join-Path $projectRoot "build\infinityfree_download_upload"
$chunkRoot = Join-Path $workRoot "chunks"
$deployerPath = Join-Path $workRoot "_campusfix_file_deploy.php"
$deployId = "file" + (Get-Date -Format "yyyyMMddHHmmss")
$chunkPrefix = "_campusfix_${deployId}.part"
$remoteDeployerName = "_campusfix_deploy.php"

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
  $encoding = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllLines($Path, $Lines, $encoding)
}

function New-FtpUri([string]$RemoteFilePath) {
  $trimmed = $RemoteFilePath.Trim("/")
  $escaped = ($trimmed -split "/" | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join "/"
  return "ftp://${FtpHost}:$FtpPort/$escaped"
}

function Invoke-FtpUpload([string]$SourcePath, [string]$RemoteFilePath) {
  $uri = New-FtpUri $RemoteFilePath
  & curl.exe --silent --show-error --ssl-no-revoke --ftp-pasv --ftp-create-dirs --user "${FtpUsername}:${FtpPassword}" -T $SourcePath $uri
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to upload $RemoteFilePath"
  }
  Write-Host "Uploaded $RemoteFilePath"
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
      $chunkPath = Join-Path $chunkRoot ("{0}{1:D3}" -f $chunkPrefix, $index)
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
  $args = @(
    "--silent",
    "--show-error",
    "--ssl-no-revoke",
    "-A",
    "Mozilla/5.0"
  )
  if (-not [string]::IsNullOrWhiteSpace($ChallengeCookie)) {
    $args += @("-b", "__test=$ChallengeCookie")
  }
  $args += $uri

  Write-Host "Running remote action: $Action"
  $content = & curl.exe @args
  if ($LASTEXITCODE -ne 0) {
    throw "Remote action failed: $Action"
  }
  Write-Host $content
  return $content | ConvertFrom-Json
}

New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

$deployer = @'
<?php
declare(strict_types=1);

const CAMPUSFIX_TOKEN = '__TOKEN__';
const CAMPUSFIX_CHUNK_PREFIX = '__CHUNK_PREFIX__';
const CAMPUSFIX_REMOTE_PATH = '__REMOTE_PATH__';

header('Content-Type: application/json');
set_time_limit(300);

function respond(array $payload, int $status = 200): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_PRETTY_PRINT);
    exit;
}

if (! hash_equals(CAMPUSFIX_TOKEN, $_GET['token'] ?? '')) {
    respond(['ok' => false, 'error' => 'Forbidden'], 403);
}

$action = $_GET['action'] ?? 'status';

if ($action === 'status') {
    respond(['ok' => true, 'php' => PHP_VERSION, 'dir' => __DIR__]);
}

if ($action === 'assemble') {
    $target = __DIR__ . DIRECTORY_SEPARATOR . str_replace(['/', '\\'], DIRECTORY_SEPARATOR, CAMPUSFIX_REMOTE_PATH);
    $targetDir = dirname($target);
    if (! is_dir($targetDir) && ! mkdir($targetDir, 0775, true) && ! is_dir($targetDir)) {
        respond(['ok' => false, 'error' => 'Could not create target directory.'], 500);
    }

    $chunks = glob(__DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_CHUNK_PREFIX . '*');
    if (! is_array($chunks) || count($chunks) === 0) {
        respond(['ok' => false, 'error' => 'Chunks are missing.'], 404);
    }
    sort($chunks, SORT_NATURAL);

    $output = fopen($target, 'wb');
    if ($output === false) {
        respond(['ok' => false, 'error' => 'Could not create target file.'], 500);
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

    respond([
        'ok' => true,
        'action' => 'assemble',
        'chunks' => count($chunks),
        'path' => CAMPUSFIX_REMOTE_PATH,
        'size' => filesize($target),
    ]);
}

if ($action === 'cleanup') {
    $chunks = glob(__DIR__ . DIRECTORY_SEPARATOR . CAMPUSFIX_CHUNK_PREFIX . '*');
    if (is_array($chunks)) {
        foreach ($chunks as $chunk) {
            @unlink($chunk);
        }
    }
    @unlink(__FILE__);
    respond(['ok' => true, 'action' => 'cleanup']);
}

respond(['ok' => false, 'error' => 'Unknown action.'], 400);
'@

$remotePathForPhp = $RemotePath.TrimStart("/")
$deployer = $deployer.Replace("__TOKEN__", $Token)
$deployer = $deployer.Replace("__CHUNK_PREFIX__", $chunkPrefix)
$deployer = $deployer.Replace("__REMOTE_PATH__", $remotePathForPhp)
Write-Utf8NoBom $deployerPath ($deployer -split "`r?`n")

Invoke-FtpUpload $deployerPath "$RemoteRoot/$remoteDeployerName"

$chunks = Split-FileForUpload $LocalFile
foreach ($chunk in $chunks) {
  Invoke-FtpUpload $chunk "$RemoteRoot/$(Split-Path -Leaf $chunk)"
}

Invoke-Deployer "status" | Out-Null
Invoke-Deployer "assemble" | Out-Null

if (-not [string]::IsNullOrWhiteSpace($MetadataFile) -and
    -not [string]::IsNullOrWhiteSpace($MetadataRemotePath)) {
  Invoke-FtpUpload $MetadataFile "$RemoteRoot/$($MetadataRemotePath.TrimStart('/'))"
}

Invoke-Deployer "cleanup" | Out-Null

$publicUrlPath = $RemotePath.TrimStart("/")
if ($publicUrlPath.StartsWith("public/", [System.StringComparison]::OrdinalIgnoreCase)) {
  $publicUrlPath = $publicUrlPath.Substring("public/".Length)
}

Write-Host ""
Write-Host "Uploaded download file:"
Write-Host "$($SiteUrl.TrimEnd('/'))/$publicUrlPath"
