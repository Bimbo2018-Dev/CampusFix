param(
  [string]$Flutter = "flutter",
  [Parameter(Mandatory = $true)]
  [string]$ApiBase,
  [string]$AndroidApkUrl = "",
  [string]$WindowsAppUrl = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$outRoot = Join-Path $projectRoot "build\infinityfree"
$webOut = Join-Path $outRoot "web"
$zipPath = Join-Path $outRoot "campusfix-infinityfree-web.zip"

function New-ZipFromDirectory([string]$SourceDirectory, [string]$DestinationZip) {
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  if (Test-Path $DestinationZip) {
    Remove-Item -LiteralPath $DestinationZip -Force
  }

  $sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path.TrimEnd("\", "/")
  $zip = [System.IO.Compression.ZipFile]::Open($DestinationZip, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    Get-ChildItem -LiteralPath $sourceRoot -Directory -Recurse -Force | ForEach-Object {
      $relativePath = $_.FullName.Substring($sourceRoot.Length + 1).Replace("\", "/").TrimEnd("/") + "/"
      $zip.CreateEntry($relativePath) | Out-Null
    }

    Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force | ForEach-Object {
      $relativePath = $_.FullName.Substring($sourceRoot.Length + 1).Replace("\", "/")
      [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip,
        $_.FullName,
        $relativePath,
        [System.IO.Compression.CompressionLevel]::Optimal
      ) | Out-Null
    }
  } finally {
    $zip.Dispose()
  }
}

Push-Location $projectRoot
try {
  $buildArgs = @(
    "build",
    "web",
    "--release",
    "--dart-define=CAMPUSFIX_API_BASE=$ApiBase"
  )

  if (-not [string]::IsNullOrWhiteSpace($AndroidApkUrl)) {
    $buildArgs += "--dart-define=CAMPUSFIX_ANDROID_APK_URL=$AndroidApkUrl"
  }

  if (-not [string]::IsNullOrWhiteSpace($WindowsAppUrl)) {
    $buildArgs += "--dart-define=CAMPUSFIX_WINDOWS_APP_URL=$WindowsAppUrl"
  }

  & $Flutter @buildArgs
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build web failed."
  }

  if (Test-Path $webOut) {
    $resolvedProject = (Resolve-Path -LiteralPath $projectRoot).Path
    $resolvedWebOut = (Resolve-Path -LiteralPath $webOut).Path
    if (-not $resolvedWebOut.StartsWith($resolvedProject, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove path outside project root: $resolvedWebOut"
    }
    Remove-Item -LiteralPath $webOut -Recurse -Force
  }

  New-Item -ItemType Directory -Path $webOut -Force | Out-Null
  Copy-Item -Path (Join-Path $projectRoot "build\web\*") -Destination $webOut -Recurse -Force

  $downloadsPath = Join-Path $webOut "downloads"
  if (Test-Path $downloadsPath) {
    Remove-Item -LiteralPath $downloadsPath -Recurse -Force
  }

  New-ZipFromDirectory $webOut $zipPath

  Write-Host "InfinityFree web package ready:"
  Write-Host "  $zipPath"
  Write-Host "One-site setup: upload the contents of build\infinityfree\web to htdocs\public."
  Write-Host "Two-site setup: upload the contents of build\infinityfree\web to the frontend site's htdocs folder."
} finally {
  Pop-Location
}
