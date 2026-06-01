param(
  [string]$Repo = "Bimbo2018-Dev/CampusFix",
  [string]$Tag = "",
  [string]$ApkPath = "",
  [string]$MetadataPath = "",
  [switch]$Draft
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ApkPath)) {
  $ApkPath = Join-Path $projectRoot "web\downloads\CampusFix.apk"
}
if ([string]::IsNullOrWhiteSpace($MetadataPath)) {
  $MetadataPath = Join-Path $projectRoot "web\downloads\campusfix_android_version.json"
}
if ([string]::IsNullOrWhiteSpace($Tag)) {
  $Tag = "android-v" + (Get-Date -Format "yyyy.MM.dd-HHmm")
}

$ApkPath = (Resolve-Path -LiteralPath $ApkPath).Path
$MetadataPath = (Resolve-Path -LiteralPath $MetadataPath).Path

function Invoke-Gh([string[]]$Arguments) {
  & gh @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "gh failed: gh $($Arguments -join ' ')"
  }
}

Invoke-Gh @("auth", "status")

try {
  $existing = & gh release view $Tag --repo $Repo --json tagName 2>$null
  $releaseExists = $LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($existing)
} catch {
  $releaseExists = $false
}

if ($releaseExists) {
  Invoke-Gh @(
    "release",
    "upload",
    $Tag,
    $ApkPath,
    $MetadataPath,
    "--repo",
    $Repo,
    "--clobber"
  )
} else {
  $args = @(
    "release",
    "create",
    $Tag,
    $ApkPath,
    $MetadataPath,
    "--repo",
    $Repo,
    "--title",
    "CampusFix Android $Tag",
    "--notes",
    "CampusFix Android APK release. Download CampusFix.apk to install on Android."
  )
  if ($Draft) {
    $args += "--draft"
  }
  Invoke-Gh $args
}

Write-Host ""
Write-Host "CampusFix GitHub Release is ready:"
Write-Host "https://github.com/$Repo/releases/latest"
Write-Host ""
Write-Host "Direct APK download:"
Write-Host "https://github.com/$Repo/releases/latest/download/CampusFix.apk"
