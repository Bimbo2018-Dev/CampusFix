param(
  [string]$Flutter = "flutter",
  [string]$ApiBase = "",
  [string]$ApiCookie = "",
  [string]$DownloadUrl = "",
  [string]$UpdateMetadataUrl = "",
  [switch]$SplitPerAbi,
  [ValidateSet("arm64-v8a", "armeabi-v7a", "x86_64")]
  [string]$PreferredAbi = "arm64-v8a"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$apkOutputDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"
$apkSource = Join-Path $apkOutputDir "app-release.apk"
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

  $buildNumber = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $buildName = "1.0.0"
  $buildArgs = @(
    "build",
    "apk",
    "--release",
    "--build-name=$buildName",
    "--build-number=$buildNumber"
  )
  if ($SplitPerAbi) {
    $buildArgs += "--split-per-abi"
  }
  $androidSignature = "android-" + ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $buildArgs += "--dart-define=CAMPUSFIX_ANDROID_BUILD_SIGNATURE=$androidSignature"
  if (-not [string]::IsNullOrWhiteSpace($ApiBase)) {
    $buildArgs += "--dart-define=CAMPUSFIX_API_BASE=$ApiBase"
    Write-Host "Building CampusFix APK with API base $ApiBase"
  }
  if (-not [string]::IsNullOrWhiteSpace($ApiCookie)) {
    $buildArgs += "--dart-define=CAMPUSFIX_API_COOKIE=$ApiCookie"
    Write-Host "Building CampusFix APK with API cookie support"
  }
  if (-not [string]::IsNullOrWhiteSpace($UpdateMetadataUrl)) {
    $buildArgs += "--dart-define=CAMPUSFIX_ANDROID_UPDATE_METADATA_URL=$UpdateMetadataUrl"
    Write-Host "Building CampusFix APK with update metadata $UpdateMetadataUrl"
  }

  & $Flutter @buildArgs
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk failed."
  }

  if ($SplitPerAbi) {
    $splitApk = Join-Path $apkOutputDir "app-$PreferredAbi-release.apk"
    if (-not (Test-Path -LiteralPath $splitApk)) {
      throw "Could not find split APK: $splitApk"
    }
    $apkSource = $splitApk
    Write-Host "Using smaller $PreferredAbi APK at $apkSource"
  }

  New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
  Copy-Item -LiteralPath $apkSource -Destination $apkTarget -Force

  $apkItem = Get-Item -LiteralPath $apkTarget
  $metadata = [ordered]@{
    app = "CampusFix"
    platform = "android"
    signature = $androidSignature
    version = "$buildName+$buildNumber"
    buildName = $buildName
    buildNumber = $buildNumber
    apiBase = $ApiBase
    file = "CampusFix.apk"
    downloadPath = if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
      "/downloads/CampusFix.apk"
    } else {
      $DownloadUrl
    }
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
