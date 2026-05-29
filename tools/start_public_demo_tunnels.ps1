param(
  [string]$Flutter = "flutter",
  [int]$BackendPort = 8001,
  [int]$WebPort = 8791,
  [string]$AndroidApkUrl = "https://github.com/Chuan2018-dev/CAMPUSFIX/releases/latest/download/CampusFix.apk",
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend"
$nodeServer = Join-Path $projectRoot "tools\campusfix_lan_server.js"
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$logRoot = Join-Path $projectRoot "tools\public_demo_logs\$runId"
$urlsFile = Join-Path $projectRoot "tools\public_demo_urls.txt"

function Quote-PSLiteral([string]$value) {
  return "'" + ($value -replace "'", "''") + "'"
}

function Resolve-Cloudflared {
  $command = Get-Command cloudflared -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $knownPaths = @(
    "C:\Program Files\cloudflared\cloudflared.exe",
    "C:\Program Files (x86)\cloudflared\cloudflared.exe"
  )

  foreach ($path in $knownPaths) {
    if (Test-Path -LiteralPath $path) {
      return $path
    }
  }

  throw "cloudflared is not installed. Install it with: winget install --id Cloudflare.cloudflared --exact"
}

function Test-HttpReady([string]$url) {
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
    return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
  } catch {
    return $false
  }
}

function Wait-HttpReady([string]$url, [string]$name, [int]$seconds = 45) {
  $deadline = (Get-Date).AddSeconds($seconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-HttpReady $url) {
      return
    }
    Start-Sleep -Seconds 1
  }

  throw "$name did not become ready at $url"
}

function Start-HiddenPowerShell([string]$name, [string]$command) {
  Write-Host "Starting $name..."
  return Start-Process `
    -FilePath "powershell" `
    -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $command) `
    -WindowStyle Hidden `
    -PassThru
}

function Start-Tunnel([string]$name, [string]$localUrl, [string]$cloudflaredPath, [string]$logDirectory) {
  $stdoutLog = Join-Path $logDirectory "$name.out.log"
  $stderrLog = Join-Path $logDirectory "$name.err.log"
  Write-Host "Opening $name tunnel for $localUrl..."

  $process = Start-Process `
    -FilePath $cloudflaredPath `
    -ArgumentList @("tunnel", "--url", $localUrl, "--no-autoupdate") `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -WindowStyle Hidden `
    -PassThru

  $deadline = (Get-Date).AddSeconds(60)
  $publicUrl = $null
  while ((Get-Date) -lt $deadline) {
    $content = ""
    if (Test-Path -LiteralPath $stdoutLog) {
      $content += Get-Content -LiteralPath $stdoutLog -Raw -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $stderrLog) {
      $content += Get-Content -LiteralPath $stderrLog -Raw -ErrorAction SilentlyContinue
    }

    $match = [regex]::Match($content, "https://[a-zA-Z0-9-]+\.trycloudflare\.com")
    if ($match.Success) {
      $publicUrl = $match.Value
      break
    }

    if ($process.HasExited) {
      throw "$name tunnel stopped early. Check logs in $logDirectory"
    }

    Start-Sleep -Seconds 1
  }

  if ([string]::IsNullOrWhiteSpace($publicUrl)) {
    throw "Could not get $name public URL. Check logs in $logDirectory"
  }

  return [pscustomobject]@{
    Name = $name
    ProcessId = $process.Id
    Url = $publicUrl
    StdoutLog = $stdoutLog
    StderrLog = $stderrLog
  }
}

New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$cloudflared = Resolve-Cloudflared
$backendLocalUrl = "http://127.0.0.1:$BackendPort"
$backendHealthUrl = "$backendLocalUrl/api/health"

Push-Location $projectRoot
try {
  if (-not (Test-HttpReady $backendHealthUrl)) {
    $backendCommand = "Set-Location -LiteralPath $(Quote-PSLiteral $backendRoot); php artisan config:clear; php artisan serve --host=127.0.0.1 --port=$BackendPort"
    Start-HiddenPowerShell "CampusFix Laravel API" $backendCommand | Out-Null
  }

  Wait-HttpReady $backendHealthUrl "CampusFix Laravel API"
  $backendTunnel = Start-Tunnel "backend" $backendLocalUrl $cloudflared $logRoot
  $apiBase = "$($backendTunnel.Url)/api"

  if (-not $SkipBuild) {
    Write-Host "Building Flutter web with API base $apiBase..."
    & $Flutter build web --release "--dart-define=CAMPUSFIX_API_BASE=$apiBase" "--dart-define=CAMPUSFIX_ANDROID_APK_URL=$AndroidApkUrl"
  }

  $webLocalUrl = "http://127.0.0.1:$WebPort"
  if (-not (Test-HttpReady $webLocalUrl)) {
    $webCommand = "Set-Location -LiteralPath $(Quote-PSLiteral $projectRoot); `$env:CAMPUSFIX_HOST='127.0.0.1'; `$env:CAMPUSFIX_PORT='$WebPort'; node $(Quote-PSLiteral $nodeServer)"
    Start-HiddenPowerShell "CampusFix web server" $webCommand | Out-Null
  }

  Wait-HttpReady $webLocalUrl "CampusFix web server"
  $webTunnel = Start-Tunnel "web" $webLocalUrl $cloudflared $logRoot

  $output = @"
CampusFix public demo links
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Frontend PWA:
$($webTunnel.Url)

Laravel API:
$($backendTunnel.Url)/api

Health check:
$($backendTunnel.Url)/api/health

Android APK:
$AndroidApkUrl

Process IDs:
Backend tunnel: $($backendTunnel.ProcessId)
Web tunnel: $($webTunnel.ProcessId)

Logs:
$logRoot

Keep this laptop awake while presenting. These trycloudflare.com URLs change every time the tunnels are restarted.
"@

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($urlsFile, $output, $utf8NoBom)

  Write-Host ""
  Write-Host $output
} finally {
  Pop-Location
}
