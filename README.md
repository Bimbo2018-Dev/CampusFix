# CampusFix

CampusFix is a Flutter + Laravel + MySQL campus issue reporting system for Students, Teachers, and Admins. It supports registration, Sanctum login, role-based dashboards, report CRUD, teacher validation, admin status updates, report notes, assignment workflows, before/after photos, SLA tracking, offline report queueing, duplicate detection, admin account controls, CSV/PDF exports, PWA install, and Android APK download builds.

## Project Structure

```text
lib/                 Flutter app
backend/             Laravel REST API
docs/                SRS, User Stories, API list, ERD, project documentation
database/sql/        MySQL export file
tools/               PWA/APK helper scripts
```

## Demo Accounts

- Student: `student@campusfix.app` / `student123`
- Teacher: `teacher@campusfix.app` / `teacher123`
- Admin: `admin@campusfix.app` / `admin123`

## Backend Setup

CampusFix uses MySQL database `campusfix_api`. On this Laragon machine, port `8000` is already used by another PHP process, so the CampusFix API runs on `8001`.

```powershell
cd C:\laragon\www\CampusFix\backend
composer install
copy .env.example .env
php artisan key:generate
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS campusfix_api CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8001
```

API health check:

```text
http://127.0.0.1:8001/api/health
```

## Flutter Setup

```powershell
cd C:\laragon\www\CampusFix
flutter pub get
flutter run -d chrome --dart-define=CAMPUSFIX_API_BASE=http://127.0.0.1:8001/api
```

For phone testing on the same Wi-Fi, replace `127.0.0.1` with the laptop LAN IP:

```powershell
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8791 --dart-define=CAMPUSFIX_API_BASE=http://YOUR_LAPTOP_IP:8001/api
```

Then open this on the phone:

```text
http://YOUR_LAPTOP_IP:8791
```

## API and Database

- API routes: `docs/API.md`
- ERD: `docs/ERD.md`
- SQL export: `database/sql/campusfix_mysql_export.sql`
- Laravel migrations: `backend/database/migrations`
- Seed data: `backend/database/seeders/DatabaseSeeder.php`

The Flutter app is API-first. If the API is unavailable during a demo, it can still fall back to local prototype data, but the full project workflow is Laravel + MySQL.

## Workflow Features

- Admin Action Center for urgent, overdue, unassigned, needs-validation, and offline-queued reports.
- Report assignment to campus response teams.
- Progress timeline with submitted, reviewed, assigned, in-progress, and resolved states.
- Problem photo and resolution photo support.
- Duplicate report warning before submission.
- SLA timers based on priority.
- Offline queue for reports submitted while the API is temporarily unreachable.
- QR room/location code input for fast location filling.
- CSV and PDF report exports for admins.
- Admin account management for activation, role, and department updates.

## Progressive Web App

CampusFix is configured as an installable PWA with manifest, standalone display mode, theme colors, maskable icons, Flutter service worker, and update checking.

```powershell
flutter build web
node .\tools\campusfix_lan_server.js
```

When the web app is opened from a phone using `http://YOUR_LAPTOP_IP:8791`, CampusFix automatically connects to `http://YOUR_LAPTOP_IP:8001/api`. Do not build the LAN PWA with `127.0.0.1` as the API URL because phones treat `127.0.0.1` as the phone itself.

Users can install the PWA from Chrome, Edge, Brave, or Android browser. On a laptop or desktop, use the in-app **Install App** button or the browser install icon in the address bar. The APK is only for Android devices and will download as a file on Windows.

## Free Cloud Deployment

Recommended free-friendly hosting stack:

- Flutter PWA: Cloudflare Pages
- Laravel API demo: Cloudflare Tunnel from your laptop for zero-card school presentation
- Laravel API: Alwaysdata Free Public Cloud only if the account does not require card validation
- Laravel API fallback: InfinityFree shared PHP hosting for capstone demo use
- MySQL database: Alwaysdata MariaDB or Aiven MySQL Free
- Report photos: Cloudinary
- Android APK download: GitHub Releases

Deployment files have been added:

- `backend/Dockerfile` and `backend/docker/start.sh` for Koyeb.
- `render.yaml` for no-card Render deployment.
- `wrangler.toml` and `.github/workflows/deploy_cloudflare_pages.yml` for Cloudflare Pages.
- `.github/workflows/release_android_apk.yml` for GitHub Release APK builds.
- `tools/build_cloudflare_web.ps1` for a local Cloudflare-style web build.
- `tools/start_public_demo_tunnels.ps1` for zero-card public demo links through Cloudflare Tunnel.
- `tools/connect_free_cloud_stack.ps1` for assisted GitHub, Koyeb, Cloudflare, and APK release deployment.
- `docs/DEPLOYMENT.md` for the full setup checklist and required secrets/variables.

Cloud deployment uses `CAMPUSFIX_API_BASE` for the Koyeb API URL and `CAMPUSFIX_ANDROID_APK_URL` for the GitHub Release APK URL. Cloudinary can be enabled with `CAMPUSFIX_IMAGE_DRIVER=cloudinary`.

For a demo presentation without credit-card validation, run:

```powershell
.\tools\start_public_demo_tunnels.ps1
```

It prints a temporary public PWA link and API link. Keep the laptop awake while presenting because the Laravel API and web app are running from this machine.

## Downloadable Android App

```powershell
.\tools\prepare_android_download.ps1 -Flutter 'C:\laragon\flutter\flutter\bin\flutter.bat'
```

The helper script builds the APK with the current LAN API URL, copies the APK to the web download folder, and writes `campusfix_android_version.json` so installed Android apps can detect newer builds. Android will not silently install APK updates; CampusFix shows an update dialog and opens the APK download for the user to install.

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
web/downloads/CampusFix.apk
web/downloads/campusfix_android_version.json
```

## Validation Commands

```powershell
flutter analyze
flutter test

cd backend
php artisan test
php artisan route:list --path=api
```

## Documentation Deliverables

- SRS: `docs/SRS.md`
- User Stories and Backlog: `docs/USER_STORIES.md`
- API List: `docs/API.md`
- ERD: `docs/ERD.md`
- Project Documentation: `docs/PROJECT_DOCUMENTATION.md`
- Cloud Deployment Guide: `docs/DEPLOYMENT.md`

## Future Improvements

- Firebase authentication
- Laravel deployment with environment-specific API URLs
- Supabase backend option
- Push notifications
- Real image object storage
- Admin analytics charts
- Email notifications
- Backend-managed role permissions
- Native camera QR scanner integration
- Signed production APK/AAB release through Play Store or MDM
