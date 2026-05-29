# CampusFix Free Cloud Deployment Guide

This guide deploys CampusFix with the recommended free-friendly stack.

If Koyeb asks for bank/payment details, use one of these no-card alternatives:

- Laravel REST API demo: Cloudflare Tunnel from your laptop, best zero-card presentation option
- Laravel REST API: Alwaysdata Free Public Cloud, if your account does not require card validation
- Laravel REST API fallback: InfinityFree shared PHP hosting
- Laravel REST API fallback: Render Free Web Service, only if your free slot is still available
- MySQL database: Aiven MySQL Free

Render's first free web service deploy does not require payment, and Aiven's free account does not require payment details.

- Flutter PWA: Cloudflare Pages
- Laravel REST API: Alwaysdata, Render, Koyeb, or InfinityFree
- MySQL database: Aiven MySQL Free
- Report photos: Cloudinary
- Android APK downloads: GitHub Releases

## 0. Cloudflare Tunnel Public Demo, Zero Credit Card

Use this option for a capstone/demo presentation when Koyeb, Alwaysdata, or other hosts ask for bank/card validation.

This setup does not permanently deploy the Laravel backend to a hosting provider. Instead, it:

- Runs Laravel on this laptop.
- Uses the Aiven cloud MySQL database.
- Uses Cloudinary for report photos.
- Builds a downloadable Android APK with the current public API tunnel URL.
- Builds the Flutter PWA with the public tunnel API URL.
- Opens two temporary Cloudflare `trycloudflare.com` HTTPS links, one for the API and one for the PWA.

Requirements:

- Keep the laptop on and connected to the internet during the demo.
- Do not close the background Laravel/web/tunnel processes while presenting.
- The public URLs change every time the tunnels are restarted.

Run:

```powershell
cd C:\laragon\www\CampusFix
.\tools\start_public_demo_tunnels.ps1
```

The script prints:

```text
Frontend PWA: https://<temporary-name>.trycloudflare.com
Laravel API:  https://<temporary-name>.trycloudflare.com/api
```

Open the frontend PWA link on your laptop and phone. Registration, login, report submission, admin reports, and photo upload will use the same Aiven database through the Laravel API tunnel.

The Android download button uses:

```text
https://<frontend-pwa-tunnel>/downloads/CampusFix.apk
```

That APK is rebuilt by the script so the installed Android app uses the same public Laravel API tunnel during the demo.

For a real always-online deployment, use Cloudflare Pages plus a permanent Laravel host. For a school presentation, this tunnel setup is the fastest no-card route.

## 1. Aiven MySQL

Create a free Aiven MySQL service, then copy these values into your backend host environment variables:

```text
DB_CONNECTION=mysql
DB_HOST=<AIVEN_MYSQL_HOST>
DB_PORT=<AIVEN_MYSQL_PORT>
DB_DATABASE=<AIVEN_MYSQL_DATABASE>
DB_USERNAME=<AIVEN_MYSQL_USER>
DB_PASSWORD=<AIVEN_MYSQL_PASSWORD>
AIVEN_CA_CERT_BASE64=<BASE64_ENCODED_AIVEN_CA_CERT>
```

The Docker start script decodes `AIVEN_CA_CERT_BASE64` to `/tmp/aiven-ca.pem` and exposes it to Laravel as `MYSQL_ATTR_SSL_CA`.

## 2. Cloudinary

Create a free Cloudinary account and get the cloud name, API key, and API secret.

Add these to Render or Koyeb:

```text
CAMPUSFIX_IMAGE_DRIVER=cloudinary
CLOUDINARY_CLOUD_NAME=<CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<CLOUDINARY_API_SECRET>
```

When Cloudinary is enabled, CampusFix uploads report photos and resolution photos to Cloudinary and stores the returned HTTPS URL in MySQL. Local development still supports inline data URLs when `CAMPUSFIX_IMAGE_DRIVER=local`.

## 3. Alwaysdata Laravel API, No Bank Details

Use this option first if Koyeb asks for bank details and Render free is already used by another project.

Why Alwaysdata fits CampusFix:

- Supports PHP on its Public Cloud plans.
- Supports MariaDB/MySQL databases.
- Supports SSH/SFTP access.
- Supports Composer for PHP packages.
- Supports Laravel through its PHP/marketplace documentation.

Recommended deployment shape:

```text
Flutter PWA        Cloudflare Pages
Laravel API        Alwaysdata
Database           Alwaysdata MariaDB or Aiven MySQL
Photos             Cloudinary
APK downloads      GitHub Releases
```

Alwaysdata steps:

1. Create an Alwaysdata free account.
2. Create a PHP site, for example `campusfix.alwaysdata.net`.
3. Set the PHP version to PHP 8.3 or newer.
4. Create a MariaDB database, or keep using Aiven MySQL.
5. Enable SSH access.
6. Upload or clone the GitHub repo.
7. Inside the `backend` folder, run:

```bash
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
php artisan migrate --force
php artisan db:seed --force
php artisan config:cache
```

8. Set the Alwaysdata website root to:

```text
backend/public
```

9. Set the backend `.env`:

```text
APP_NAME=CampusFix
APP_ENV=production
APP_DEBUG=false
APP_URL=https://campusfix.alwaysdata.net
DB_CONNECTION=mysql
DB_HOST=<ALWAYSDATA_OR_AIVEN_DB_HOST>
DB_PORT=3306
DB_DATABASE=<DATABASE_NAME>
DB_USERNAME=<DATABASE_USER>
DB_PASSWORD=<DATABASE_PASSWORD>
CAMPUSFIX_IMAGE_DRIVER=cloudinary
CLOUDINARY_CLOUD_NAME=<CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<CLOUDINARY_API_SECRET>
```

10. Verify:

```text
https://campusfix.alwaysdata.net/api/health
```

Use this API URL for Flutter/Cloudflare/GitHub Actions:

```text
https://campusfix.alwaysdata.net/api
```

Alwaysdata limitation: the free account is smaller than Render/Koyeb, so keep uploaded photos on Cloudinary and avoid storing large files in Laravel storage.

## 4. InfinityFree Laravel API Fallback, No Bank Details

Use InfinityFree only if Alwaysdata is not available. InfinityFree is explicitly no credit card, supports PHP 8.3, MySQL/MariaDB, free SSL, and free subdomains. It is less developer-friendly for Laravel because it is FTP/control-panel based and does not provide the same SSH/Composer workflow.

Recommended shape:

```text
Flutter PWA        Cloudflare Pages
Laravel API        InfinityFree shared hosting
Database           InfinityFree MySQL
Photos             Cloudinary
APK downloads      GitHub Releases
```

InfinityFree notes:

- Use PHP 8.3.
- Import SQL manually through phpMyAdmin or run migrations locally then export SQL.
- Upload a production-ready Laravel backend with `vendor/` already installed.
- Point the domain/subdomain document root to Laravel `public`.
- If document root cannot be changed, copy Laravel `public` contents to the hosting web root and adjust `index.php` paths to point to the Laravel app folder.

InfinityFree is okay for capstone demonstration, but Alwaysdata is cleaner for Laravel because of SSH and Composer.

## 5. Render Laravel API, No Bank Details

Use this option if Koyeb asks for bank details.

CampusFix includes `render.yaml` in the repo root. Render can create the service from that file.

1. Sign in to Render.
2. Choose **New > Blueprint**.
3. Connect `https://github.com/Chuan2018-dev/CAMPUSFIX`.
4. Select the `main` branch.
5. Render detects `render.yaml`.
6. Fill the required secret values when prompted.

Required Render secret/env values:

```text
APP_KEY=<GENERATE_WITH_php_artisan_key_generate_show>
DB_HOST=<AIVEN_MYSQL_HOST>
DB_PORT=<AIVEN_MYSQL_PORT>
DB_DATABASE=<AIVEN_MYSQL_DATABASE>
DB_USERNAME=<AIVEN_MYSQL_USER>
DB_PASSWORD=<AIVEN_MYSQL_PASSWORD>
AIVEN_CA_CERT_BASE64=<BASE64_ENCODED_AIVEN_CA_CERT>
CLOUDINARY_CLOUD_NAME=<CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<CLOUDINARY_API_SECRET>
```

Generate `APP_KEY` locally:

```powershell
cd C:\laragon\www\CampusFix\backend
php artisan key:generate --show
```

Generate the Aiven certificate base64 value:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\aiven-ca.pem"))
```

After deployment, verify:

```text
https://campusfix-api.onrender.com/api/health
```

Expected:

```json
{"status":"ok","app":"CampusFix"}
```

Use this API URL for Flutter/Cloudflare/GitHub Actions:

```text
https://campusfix-api.onrender.com/api
```

Render Free limitation: the backend may sleep after inactivity, so the first request after a pause can be slow.

## 6. Koyeb Laravel API

Deploy the `backend/` folder as a Docker service.

Recommended Koyeb environment variables:

```text
APP_NAME=CampusFix
APP_ENV=production
APP_KEY=<GENERATE_WITH_php_artisan_key_generate_show>
APP_DEBUG=false
APP_URL=https://<YOUR_KOYEB_APP>.koyeb.app
LOG_CHANNEL=stderr
RUN_MIGRATIONS=true
RUN_SEEDER=true

DB_CONNECTION=mysql
DB_HOST=<AIVEN_MYSQL_HOST>
DB_PORT=<AIVEN_MYSQL_PORT>
DB_DATABASE=<AIVEN_MYSQL_DATABASE>
DB_USERNAME=<AIVEN_MYSQL_USER>
DB_PASSWORD=<AIVEN_MYSQL_PASSWORD>
AIVEN_CA_CERT_BASE64=<BASE64_ENCODED_AIVEN_CA_CERT>

CAMPUSFIX_IMAGE_DRIVER=cloudinary
CLOUDINARY_CLOUD_NAME=<CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<CLOUDINARY_API_SECRET>
```

Generate the Laravel key locally:

```powershell
cd C:\laragon\www\CampusFix\backend
php artisan key:generate --show
```

After deployment, verify:

```text
https://<YOUR_KOYEB_APP>.koyeb.app/api/health
```

Expected:

```json
{"status":"ok","app":"CampusFix"}
```

## 7. GitHub Releases for APK

The workflow `.github/workflows/release_android_apk.yml` builds `CampusFix.apk` and uploads it to a GitHub Release.

Set this GitHub repository variable:

```text
CAMPUSFIX_API_BASE=https://campusfix.alwaysdata.net/api
```

Run the workflow manually, or push a tag:

```powershell
git tag android-v1.0.0
git push origin android-v1.0.0
```

APK latest download URL format:

```text
https://github.com/<OWNER>/<REPO>/releases/latest/download/CampusFix.apk
```

APK update metadata URL format:

```text
https://github.com/<OWNER>/<REPO>/releases/latest/download/campusfix_android_version.json
```

## 8. Cloudflare Pages for Flutter PWA

Create a Cloudflare Pages project named `campusfix`.

GitHub repository variables:

```text
CLOUDFLARE_PROJECT_NAME=campusfix
CAMPUSFIX_API_BASE=https://campusfix.alwaysdata.net/api
CAMPUSFIX_ANDROID_APK_URL=https://github.com/<OWNER>/<REPO>/releases/latest/download/CampusFix.apk
```

GitHub repository secrets:

```text
CLOUDFLARE_API_TOKEN=<Cloudflare Pages edit/deploy token>
CLOUDFLARE_ACCOUNT_ID=<Cloudflare account ID>
```

The workflow `.github/workflows/deploy_cloudflare_pages.yml`:

1. Installs Flutter.
2. Runs `flutter analyze`.
3. Runs `flutter test`.
4. Builds the PWA with the Laravel API URL and GitHub APK URL.
5. Removes local APK files so Cloudflare Pages does not reject the deployment.
6. Deploys `build/web` to Cloudflare Pages.

## 9. Local Cloudflare-style Build

Use this before pushing:

```powershell
cd C:\laragon\www\CampusFix
.\tools\build_cloudflare_web.ps1 `
  -ApiBase "https://campusfix.alwaysdata.net/api" `
  -AndroidApkUrl "https://github.com/<OWNER>/<REPO>/releases/latest/download/CampusFix.apk"
```

The script builds `build/web` and removes `build/web/downloads`, because Cloudflare Pages has a single-asset size limit and the APK belongs in GitHub Releases.

## 10. Recommended Zero-card Demo Order

1. Configure Aiven MySQL in `backend/.env`.
2. Configure Cloudinary in `backend/.env`.
3. Run Laravel migrations and seeders.
4. Run `.\tools\start_public_demo_tunnels.ps1`.
5. Open the printed Frontend PWA URL on the laptop and phone.
6. Test registration, login, report creation, photo upload, admin account list, all reports, and downloadable APK button.

## 11. Recommended No-card Deployment Order

1. Create Alwaysdata free account, if it does not require card validation.
2. Create Cloudinary credentials.
3. Deploy Laravel backend to Alwaysdata.
4. Verify `https://campusfix.alwaysdata.net/api/health`.
5. Run GitHub APK release workflow.
6. Deploy Flutter PWA to Cloudflare Pages.
7. Open the Cloudflare Pages URL and test login, registration, report creation, photo upload, admin reports, and APK download.

## 12. Render No-card Deployment Order

1. Create Aiven MySQL.
2. Create Cloudinary credentials.
3. Deploy Laravel backend to Render using `render.yaml`.
4. Verify `https://campusfix-api.onrender.com/api/health`.
5. Run GitHub APK release workflow.
6. Deploy Flutter PWA to Cloudflare Pages.
7. Open the Cloudflare Pages URL and test login, registration, report creation, photo upload, admin reports, and APK download.

## 13. Koyeb Deployment Order

1. Create Aiven MySQL.
2. Create Cloudinary credentials.
3. Deploy Laravel backend to Koyeb.
4. Verify `/api/health`.
5. Run GitHub APK release workflow.
6. Deploy Flutter PWA to Cloudflare Pages.
7. Open the Cloudflare Pages URL and test login, registration, report creation, photo upload, admin reports, and APK download.

## 14. One-command Assisted Deployment

The helper script `tools/connect_free_cloud_stack.ps1` can push the repository, set GitHub Actions variables/secrets, deploy the Laravel backend to Koyeb, trigger the Android APK release workflow, and deploy the Flutter PWA to Cloudflare Pages.

For the no-card Render option, use Render's Blueprint flow with `render.yaml` for the backend, then use this script only for GitHub variables, Android release, and Cloudflare Pages.

Prepare the private deployment file:

```powershell
cd C:\laragon\www\CampusFix
copy .env.deploy.example .env.deploy
```

Fill `.env.deploy` with the real Cloudflare, Koyeb, Aiven, and Cloudinary values. This file is ignored by Git.

Then run:

```powershell
.\tools\connect_free_cloud_stack.ps1 `
  -LoginGitHub `
  -DeployKoyebBackend `
  -RunAndroidReleaseWorkflow `
  -CreateCloudflareProject `
  -DeployCloudflareNow
```

For the Aiven certificate value, encode the CA file locally:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\aiven-ca.pem"))
```
