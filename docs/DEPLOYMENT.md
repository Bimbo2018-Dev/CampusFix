# CampusFix Free Cloud Deployment Guide

This guide deploys CampusFix with the recommended free-friendly stack:

- Flutter PWA: Cloudflare Pages
- Laravel REST API: Koyeb
- MySQL database: Aiven MySQL Free
- Report photos: Cloudinary
- Android APK downloads: GitHub Releases

## 1. Aiven MySQL

Create a free Aiven MySQL service, then copy these values into Koyeb environment variables:

```text
DB_CONNECTION=mysql
DB_HOST=<AIVEN_MYSQL_HOST>
DB_PORT=<AIVEN_MYSQL_PORT>
DB_DATABASE=<AIVEN_MYSQL_DATABASE>
DB_USERNAME=<AIVEN_MYSQL_USER>
DB_PASSWORD=<AIVEN_MYSQL_PASSWORD>
AIVEN_CA_CERT=<PASTE_AIVEN_CA_CERT_CONTENT_HERE>
```

The Koyeb Docker start script writes `AIVEN_CA_CERT` to `/tmp/aiven-ca.pem` and exposes it to Laravel as `MYSQL_ATTR_SSL_CA`.

## 2. Cloudinary

Create a free Cloudinary account and get the cloud name, API key, and API secret.

Add these to Koyeb:

```text
CAMPUSFIX_IMAGE_DRIVER=cloudinary
CLOUDINARY_CLOUD_NAME=<CLOUDINARY_CLOUD_NAME>
CLOUDINARY_API_KEY=<CLOUDINARY_API_KEY>
CLOUDINARY_API_SECRET=<CLOUDINARY_API_SECRET>
```

When Cloudinary is enabled, CampusFix uploads report photos and resolution photos to Cloudinary and stores the returned HTTPS URL in MySQL. Local development still supports inline data URLs when `CAMPUSFIX_IMAGE_DRIVER=local`.

## 3. Koyeb Laravel API

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
AIVEN_CA_CERT=<AIVEN_CA_CERT_CONTENT>

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

## 4. GitHub Releases for APK

The workflow `.github/workflows/release_android_apk.yml` builds `CampusFix.apk` and uploads it to a GitHub Release.

Set this GitHub repository variable:

```text
CAMPUSFIX_API_BASE=https://<YOUR_KOYEB_APP>.koyeb.app/api
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

## 5. Cloudflare Pages for Flutter PWA

Create a Cloudflare Pages project named `campusfix`.

GitHub repository variables:

```text
CLOUDFLARE_PROJECT_NAME=campusfix
CAMPUSFIX_API_BASE=https://<YOUR_KOYEB_APP>.koyeb.app/api
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
4. Builds the PWA with the Koyeb API URL and GitHub APK URL.
5. Removes local APK files so Cloudflare Pages does not reject the deployment.
6. Deploys `build/web` to Cloudflare Pages.

## 6. Local Cloudflare-style Build

Use this before pushing:

```powershell
cd C:\laragon\www\CampusFix
.\tools\build_cloudflare_web.ps1 `
  -ApiBase "https://<YOUR_KOYEB_APP>.koyeb.app/api" `
  -AndroidApkUrl "https://github.com/<OWNER>/<REPO>/releases/latest/download/CampusFix.apk"
```

The script builds `build/web` and removes `build/web/downloads`, because Cloudflare Pages has a single-asset size limit and the APK belongs in GitHub Releases.

## 7. Deployment Order

1. Create Aiven MySQL.
2. Create Cloudinary credentials.
3. Deploy Laravel backend to Koyeb.
4. Verify `/api/health`.
5. Run GitHub APK release workflow.
6. Deploy Flutter PWA to Cloudflare Pages.
7. Open the Cloudflare Pages URL and test login, registration, report creation, photo upload, admin reports, and APK download.
