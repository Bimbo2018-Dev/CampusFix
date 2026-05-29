param(
  [string]$Flutter = "flutter",
  [string]$ApiBase = "",
  [string]$AndroidApkUrl = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location $projectRoot
try {
  $buildArgs = @("build", "web", "--release")

  if (-not [string]::IsNullOrWhiteSpace($ApiBase)) {
    $buildArgs += "--dart-define=CAMPUSFIX_API_BASE=$ApiBase"
  }

  if (-not [string]::IsNullOrWhiteSpace($AndroidApkUrl)) {
    $buildArgs += "--dart-define=CAMPUSFIX_ANDROID_APK_URL=$AndroidApkUrl"
  }

  & $Flutter @buildArgs

  $downloadsPath = Join-Path $projectRoot "build\web\downloads"
  if (Test-Path $downloadsPath) {
    $resolvedProjectRoot = (Resolve-Path -LiteralPath $projectRoot).Path
    $resolvedDownloadsPath = (Resolve-Path -LiteralPath $downloadsPath).Path
    if (-not $resolvedDownloadsPath.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove path outside project root: $resolvedDownloadsPath"
    }
    Remove-Item -LiteralPath $downloadsPath -Recurse -Force
  }

  Write-Host "Cloudflare Pages web build ready at build\web"
} finally {
  Pop-Location
}
