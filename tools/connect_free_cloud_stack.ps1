param(
  [string]$EnvFile = ".env.deploy",
  [switch]$LoginGitHub,
  [switch]$CreateCloudflareProject,
  [switch]$DeployCloudflareNow,
  [switch]$DeployKoyebBackend,
  [switch]$RunAndroidReleaseWorkflow
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

function Read-DotEnv([string]$Path) {
  $values = @{}
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing $Path. Copy .env.deploy.example to .env.deploy and fill the values first."
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
      continue
    }

    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -ne 2) {
      continue
    }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    $values[$key] = $value
  }

  return $values
}

function Require-Value($Values, [string]$Key) {
  if (-not $Values.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Values[$Key])) {
    throw "Missing required deployment value: $Key"
  }
  return $Values[$Key]
}

function Invoke-Gh([string[]]$Args) {
  & gh @Args
  if ($LASTEXITCODE -ne 0) {
    throw "gh $($Args -join ' ') failed."
  }
}

Push-Location $projectRoot
try {
  $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User') + ';' + (Join-Path $projectRoot ".tools\koyeb")
  $values = Read-DotEnv (Join-Path $projectRoot $EnvFile)

  if ($LoginGitHub) {
    gh auth login --web --git-protocol https --hostname github.com
  }
  gh auth status

  $repo = Require-Value $values "GITHUB_REPOSITORY"
  $apiBase = Require-Value $values "CAMPUSFIX_API_BASE"
  $apkUrl = Require-Value $values "CAMPUSFIX_ANDROID_APK_URL"
  $cloudflareProject = Require-Value $values "CLOUDFLARE_PROJECT_NAME"
  $cloudflareAccountId = Require-Value $values "CLOUDFLARE_ACCOUNT_ID"
  $cloudflareToken = Require-Value $values "CLOUDFLARE_API_TOKEN"
  $appKey = $values["APP_KEY"]

  if ([string]::IsNullOrWhiteSpace($appKey)) {
    Push-Location backend
    try {
      $appKey = php artisan key:generate --show
    } finally {
      Pop-Location
    }
  }

  if (-not (Test-Path .git)) {
    git init -b main
  }

  $origin = git remote get-url origin 2>$null
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($origin)) {
    git remote add origin "https://github.com/$repo.git"
  }

  git add -A
  $hasHead = git rev-parse --verify HEAD 2>$null
  if ($LASTEXITCODE -ne 0) {
    git commit -m "chore: prepare CampusFix cloud deployment"
  } elseif (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
    git commit -m "chore: update CampusFix cloud deployment"
  }

  git branch -M main
  git push -u origin main

  Invoke-Gh @("variable", "set", "CAMPUSFIX_API_BASE", "--body", $apiBase, "--repo", $repo)
  Invoke-Gh @("variable", "set", "CAMPUSFIX_ANDROID_APK_URL", "--body", $apkUrl, "--repo", $repo)
  Invoke-Gh @("variable", "set", "CLOUDFLARE_PROJECT_NAME", "--body", $cloudflareProject, "--repo", $repo)
  Invoke-Gh @("secret", "set", "CLOUDFLARE_ACCOUNT_ID", "--body", $cloudflareAccountId, "--repo", $repo)
  Invoke-Gh @("secret", "set", "CLOUDFLARE_API_TOKEN", "--body", $cloudflareToken, "--repo", $repo)

  if ($RunAndroidReleaseWorkflow) {
    Invoke-Gh @("workflow", "run", "release_android_apk.yml", "--repo", $repo, "--ref", "main")
  }

  if ($DeployKoyebBackend) {
    $koyebToken = Require-Value $values "KOYEB_TOKEN"
    $koyebApp = Require-Value $values "KOYEB_APP_NAME"
    $koyebService = Require-Value $values "KOYEB_SERVICE_NAME"
    $koyebRegion = Require-Value $values "KOYEB_REGION"
    $koyebInstanceType = Require-Value $values "KOYEB_INSTANCE_TYPE"
    $appUrl = Require-Value $values "APP_URL"
    $dbHost = Require-Value $values "DB_HOST"
    $dbPort = Require-Value $values "DB_PORT"
    $dbDatabase = Require-Value $values "DB_DATABASE"
    $dbUsername = Require-Value $values "DB_USERNAME"
    $dbPassword = Require-Value $values "DB_PASSWORD"
    $aivenCaCertBase64 = Require-Value $values "AIVEN_CA_CERT_BASE64"
    $cloudinaryCloudName = Require-Value $values "CLOUDINARY_CLOUD_NAME"
    $cloudinaryApiKey = Require-Value $values "CLOUDINARY_API_KEY"
    $cloudinaryApiSecret = Require-Value $values "CLOUDINARY_API_SECRET"

    $koyebArgs = @(
      "deploy",
      "backend",
      "$koyebApp/$koyebService",
      "--token", $koyebToken,
      "--archive-builder", "docker",
      "--archive-docker-dockerfile", "Dockerfile",
      "--instance-type", $koyebInstanceType,
      "--regions", $koyebRegion,
      "--ports", "8000:http",
      "--routes", "/:8000",
      "--env", "APP_NAME=CampusFix",
      "--env", "APP_ENV=production",
      "--env", "APP_KEY=$appKey",
      "--env", "APP_DEBUG=false",
      "--env", "APP_URL=$appUrl",
      "--env", "LOG_CHANNEL=stderr",
      "--env", "RUN_MIGRATIONS=true",
      "--env", "RUN_SEEDER=true",
      "--env", "DB_CONNECTION=mysql",
      "--env", "DB_HOST=$dbHost",
      "--env", "DB_PORT=$dbPort",
      "--env", "DB_DATABASE=$dbDatabase",
      "--env", "DB_USERNAME=$dbUsername",
      "--env", "DB_PASSWORD=$dbPassword",
      "--env", "AIVEN_CA_CERT_BASE64=$aivenCaCertBase64",
      "--env", "CAMPUSFIX_IMAGE_DRIVER=cloudinary",
      "--env", "CLOUDINARY_CLOUD_NAME=$cloudinaryCloudName",
      "--env", "CLOUDINARY_API_KEY=$cloudinaryApiKey",
      "--env", "CLOUDINARY_API_SECRET=$cloudinaryApiSecret",
      "--wait"
    )

    & ".\.tools\koyeb\koyeb.exe" @koyebArgs
    if ($LASTEXITCODE -ne 0) {
      throw "Koyeb backend deployment failed."
    }
  }

  if ($CreateCloudflareProject -or $DeployCloudflareNow) {
    $env:CLOUDFLARE_API_TOKEN = $cloudflareToken
    $env:CLOUDFLARE_ACCOUNT_ID = $cloudflareAccountId
  }

  if ($CreateCloudflareProject) {
    npx --yes wrangler@latest pages project create $cloudflareProject --production-branch main
  }

  if ($DeployCloudflareNow) {
    powershell -ExecutionPolicy Bypass -File tools\build_cloudflare_web.ps1 -ApiBase $apiBase -AndroidApkUrl $apkUrl
    npx --yes wrangler@latest pages deploy build/web --project-name $cloudflareProject --branch main
  }

  Write-Host "CampusFix deployment setup completed."
} finally {
  Pop-Location
}
