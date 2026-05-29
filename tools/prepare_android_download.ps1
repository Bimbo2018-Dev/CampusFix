param(
  [string]$Flutter = "flutter",
  [string]$ApiBase = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$apkSource = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"
$downloadDir = Join-Path $projectRoot "web\downloads"
$apkTarget = Join-Path $downloadDir "CampusFix.apk"
$metadataTarget = Join-Path $downloadDir "campusfix_android_version.json"
$servedDownloadDir = Join-Path $projectRoot "build\web\downloads"
$servedApkTarget = Join-Path $servedDownloadDir "CampusFix.apk"
$servedMetadataTarget = Join-Path $servedDownloadDir "campusfix_android_version.json"

Push-Location $projectRoot
try {
  if ([string]::IsNullOrWhiteSpace($ApiBase)) {
    $lanIp = Get-NetIPAddress -AddressFamily IPv4 |
      Where-Object {
        $_.IPAddress -notlike "127.*" -and
        $_.IPAddress -notlike "169.254.*" -and
        $_.PrefixOrigin -ne "WellKnown"
      } |
      Sort-Object @{ Expression = { if ($_.InterfaceAlias -match "Wi-Fi|Ethernet") { 0 } else { 1 } } } |
      Select-Object -First 1 -ExpandProperty IPAddress

    if ($lanIp) {
      $ApiBase = "http://${lanIp}:8001/api"
    }
  }

  $buildArgs = @("build", "apk", "--release")
  $androidSignature = "android-" + ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $buildArgs += "--dart-define=CAMPUSFIX_ANDROID_BUILD_SIGNATURE=$androidSignature"
  if (-not [string]::IsNullOrWhiteSpace($ApiBase)) {
    $buildArgs += "--dart-define=CAMPUSFIX_API_BASE=$ApiBase"
    Write-Host "Building CampusFix APK with API base $ApiBase"
  }

  & $Flutter @buildArgs
  New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
  Copy-Item -LiteralPath $apkSource -Destination $apkTarget -Force

  $apkItem = Get-Item -LiteralPath $apkTarget
  $metadata = [ordered]@{
    app = "CampusFix"
    platform = "android"
    signature = $androidSignature
    version = "1.0.0+1"
    apiBase = $ApiBase
    file = "CampusFix.apk"
    downloadPath = "/downloads/CampusFix.apk"
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    size = $apkItem.Length
    sha256 = (Get-FileHash -LiteralPath $apkTarget -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  $metadataJson = $metadata | ConvertTo-Json -Depth 5
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($metadataTarget, $metadataJson, $utf8NoBom)

  if (Test-Path (Split-Path -Parent $servedDownloadDir)) {
    New-Item -ItemType Directory -Force -Path $servedDownloadDir | Out-Null
    Copy-Item -LiteralPath $apkSource -Destination $servedApkTarget -Force
    Copy-Item -LiteralPath $metadataTarget -Destination $servedMetadataTarget -Force
  }
  Write-Host "CampusFix Android APK copied to $apkTarget"
  Write-Host "CampusFix Android update metadata copied to $metadataTarget"
} finally {
  Pop-Location
}
