param(
  [string]$Php = "php",
  [string]$Composer = "composer",
  [string]$AppUrl = "https://YOUR_INFINITYFREE_SITE.infinityfreeapp.com",
  [string]$AppKey = "",
  [string]$DbHost = "",
  [string]$DbPort = "3306",
  [string]$DbDatabase = "",
  [string]$DbUsername = "",
  [string]$DbPassword = "",
  [string]$CloudinaryCloudName = "",
  [string]$CloudinaryApiKey = "",
  [string]$CloudinaryApiSecret = "",
  [switch]$SkipComposer
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend"
$packageRoot = Join-Path $projectRoot "build\infinityfree"
$htdocsPath = Join-Path $packageRoot "htdocs"
$databaseOutPath = Join-Path $packageRoot "database"
$zipPath = Join-Path $packageRoot "campusfix-infinityfree-backend.zip"

function Assert-InProject([string]$PathToCheck) {
  $resolvedProject = (Resolve-Path -LiteralPath $projectRoot).Path
  $parent = Split-Path -Parent $PathToCheck
  if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  $resolvedParent = (Resolve-Path -LiteralPath $parent).Path
  if (-not $resolvedParent.StartsWith($resolvedProject, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside project root: $PathToCheck"
  }
}

function Copy-BackendDirectory([string]$Name) {
  $source = Join-Path $backendRoot $Name
  $destination = Join-Path $htdocsPath $Name
  if (-not (Test-Path $source)) {
    throw "Missing backend directory: $source"
  }
  Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
}

function Copy-BackendFile([string]$Name) {
  $source = Join-Path $backendRoot $Name
  if (Test-Path $source) {
    Copy-Item -LiteralPath $source -Destination (Join-Path $htdocsPath $Name) -Force
  }
}

function Format-EnvValue([string]$Value) {
  if ($null -eq $Value) {
    return '""'
  }
  return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
  $encoding = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllLines($Path, $Lines, $encoding)
}

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

Push-Location $backendRoot
try {
  if (-not $SkipComposer) {
    & $Composer install --no-dev --optimize-autoloader
    if ($LASTEXITCODE -ne 0) {
      throw "composer install failed."
    }
  }

  if (-not (Test-Path (Join-Path $backendRoot "vendor\autoload.php"))) {
    throw "backend\vendor is missing. Run this script without -SkipComposer first."
  }

  & $Php artisan config:clear
  & $Php artisan route:clear
  & $Php artisan view:clear
} finally {
  Pop-Location
}

Assert-InProject $packageRoot
foreach ($pathToRemove in @($htdocsPath, $databaseOutPath, $zipPath)) {
  if (-not (Test-Path $pathToRemove)) {
    continue
  }

  $resolvedProject = (Resolve-Path -LiteralPath $projectRoot).Path
  $resolvedPath = (Resolve-Path -LiteralPath $pathToRemove).Path
  if (-not $resolvedPath.StartsWith($resolvedProject, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove path outside project root: $resolvedPath"
  }
  Remove-Item -LiteralPath $pathToRemove -Recurse -Force
}

New-Item -ItemType Directory -Path $htdocsPath -Force | Out-Null
New-Item -ItemType Directory -Path $databaseOutPath -Force | Out-Null

foreach ($directory in @("app", "bootstrap", "config", "database", "public", "resources", "routes", "vendor")) {
  Copy-BackendDirectory $directory
}

$sqliteDatabase = Join-Path $htdocsPath "database\database.sqlite"
if (Test-Path $sqliteDatabase) {
  Remove-Item -LiteralPath $sqliteDatabase -Force
}

foreach ($file in @(".env.infinityfree.example", ".htaccess", "artisan", "composer.json", "composer.lock")) {
  Copy-BackendFile $file
}

$bootstrapCache = Join-Path $htdocsPath "bootstrap\cache"
if (Test-Path $bootstrapCache) {
  Get-ChildItem -LiteralPath $bootstrapCache -Filter "*.php" -File | Remove-Item -Force
}

foreach ($storageDirectory in @(
  "storage",
  "storage\app",
  "storage\app\public",
  "storage\framework",
  "storage\framework\cache",
  "storage\framework\cache\data",
  "storage\framework\sessions",
  "storage\framework\testing",
  "storage\framework\views",
  "storage\logs"
)) {
  New-Item -ItemType Directory -Path (Join-Path $htdocsPath $storageDirectory) -Force | Out-Null
}

$hasDbConfig = -not [string]::IsNullOrWhiteSpace($DbHost) -and
  -not [string]::IsNullOrWhiteSpace($DbDatabase) -and
  -not [string]::IsNullOrWhiteSpace($DbUsername) -and
  -not [string]::IsNullOrWhiteSpace($DbPassword)

if ($hasDbConfig) {
  if ($AppUrl -like "*YOUR_INFINITYFREE_SITE*") {
    throw "Pass your real InfinityFree site URL with -AppUrl before generating .env."
  }

  if ([string]::IsNullOrWhiteSpace($AppKey)) {
    Push-Location $backendRoot
    try {
      $generatedKey = & $Php artisan key:generate --show
      if ($LASTEXITCODE -ne 0) {
        throw "Could not generate APP_KEY."
      }
      $AppKey = ($generatedKey | Select-Object -Last 1).Trim()
    } finally {
      Pop-Location
    }
  }

  $imageDriver = "local"
  if (-not [string]::IsNullOrWhiteSpace($CloudinaryCloudName) -and
      -not [string]::IsNullOrWhiteSpace($CloudinaryApiKey) -and
      -not [string]::IsNullOrWhiteSpace($CloudinaryApiSecret)) {
    $imageDriver = "cloudinary"
  }

  $envLines = @(
    "APP_NAME=CampusFix",
    "APP_ENV=production",
    "APP_KEY=$AppKey",
    "APP_DEBUG=false",
    "APP_URL=$AppUrl",
    "",
    "APP_LOCALE=en",
    "APP_FALLBACK_LOCALE=en",
    "APP_FAKER_LOCALE=en_US",
    "",
    "APP_MAINTENANCE_DRIVER=file",
    "BCRYPT_ROUNDS=12",
    "",
    "LOG_CHANNEL=single",
    "LOG_LEVEL=error",
    "",
    "DB_CONNECTION=mysql",
    "DB_HOST=$(Format-EnvValue $DbHost)",
    "DB_PORT=$DbPort",
    "DB_DATABASE=$(Format-EnvValue $DbDatabase)",
    "DB_USERNAME=$(Format-EnvValue $DbUsername)",
    "DB_PASSWORD=$(Format-EnvValue $DbPassword)",
    "MYSQL_ATTR_SSL_CA=",
    "AIVEN_CA_CERT=",
    "",
    "SESSION_DRIVER=database",
    "SESSION_LIFETIME=120",
    "SESSION_ENCRYPT=false",
    "SESSION_PATH=/",
    "SESSION_DOMAIN=null",
    "",
    "BROADCAST_CONNECTION=log",
    "FILESYSTEM_DISK=local",
    "QUEUE_CONNECTION=sync",
    "",
    "CACHE_STORE=database",
    "",
    "MAIL_MAILER=log",
    "MAIL_FROM_ADDRESS=`"hello@example.com`"",
    "MAIL_FROM_NAME=`"`$`{APP_NAME`}`"",
    "",
    "CAMPUSFIX_IMAGE_DRIVER=$imageDriver",
    "CLOUDINARY_CLOUD_NAME=$(Format-EnvValue $CloudinaryCloudName)",
    "CLOUDINARY_API_KEY=$(Format-EnvValue $CloudinaryApiKey)",
    "CLOUDINARY_API_SECRET=$(Format-EnvValue $CloudinaryApiSecret)",
    "",
    "VITE_APP_NAME=`"`$`{APP_NAME`}`""
  )

  Write-Utf8NoBom (Join-Path $htdocsPath ".env") $envLines
  Write-Host "Generated htdocs\.env with the supplied InfinityFree database settings."
} else {
  Write-Warning "No .env was generated. Fill htdocs\.env.infinityfree.example and rename it to .env before uploading."
}

$sqlSource = Join-Path $projectRoot "database\sql\campusfix_mysql_export.sql"
if (Test-Path $sqlSource) {
  Copy-Item -LiteralPath $sqlSource -Destination (Join-Path $databaseOutPath "campusfix_mysql_export.sql") -Force
}

New-ZipFromDirectory $htdocsPath $zipPath

Write-Host ""
Write-Host "InfinityFree backend package ready:"
Write-Host "  $zipPath"
Write-Host ""
Write-Host "Upload the contents of build\infinityfree\htdocs to your InfinityFree htdocs folder."
Write-Host "Import build\infinityfree\database\campusfix_mysql_export.sql in InfinityFree phpMyAdmin."
