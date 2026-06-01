# CampusFix InfinityFree Deployment

Use this when you want CampusFix online through InfinityFree. CampusFix can run on one InfinityFree site:

- Flutter web/PWA: `https://YOUR_SITE.infinityfreeapp.com`
- Laravel API: `https://YOUR_SITE.infinityfreeapp.com/api`

Another clean option is two sites/subdomains:

- Laravel API site: `https://YOUR_API_SITE.infinityfreeapp.com`
- Flutter web/PWA site: `https://YOUR_WEB_SITE.infinityfreeapp.com`

InfinityFree can host PHP 8.3 and MySQL/MariaDB, but it uses `htdocs` as the fixed web root and does not provide the same SSH/Composer workflow as a VPS. This repo includes scripts that prepare the files locally before upload.

## 1. Create The InfinityFree Backend Site

1. Create an InfinityFree account.
2. Create a hosting account or subdomain for the API.
3. In the control panel, create a MySQL database.
4. Copy the database host, database name, username, and password.

## 2. Build The Laravel Backend Package

From the project root:

```powershell
.\tools\package_infinityfree_backend.ps1 `
  -AppUrl "https://YOUR_API_SITE.infinityfreeapp.com" `
  -DbHost "sqlXXX.infinityfree.com" `
  -DbDatabase "if0_XXXXXXXX_campusfix" `
  -DbUsername "if0_XXXXXXXX" `
  -DbPassword "YOUR_DATABASE_PASSWORD"
```

Optional Cloudinary photo storage:

```powershell
.\tools\package_infinityfree_backend.ps1 `
  -AppUrl "https://YOUR_API_SITE.infinityfreeapp.com" `
  -DbHost "sqlXXX.infinityfree.com" `
  -DbDatabase "if0_XXXXXXXX_campusfix" `
  -DbUsername "if0_XXXXXXXX" `
  -DbPassword "YOUR_DATABASE_PASSWORD" `
  -CloudinaryCloudName "YOUR_CLOUD_NAME" `
  -CloudinaryApiKey "YOUR_API_KEY" `
  -CloudinaryApiSecret "YOUR_API_SECRET"
```

The output is:

```text
build/infinityfree/campusfix-infinityfree-backend.zip
build/infinityfree/htdocs/
build/infinityfree/database/campusfix_mysql_export.sql
```

Upload the contents of `build/infinityfree/htdocs` to the site's `htdocs` folder. Import `build/infinityfree/database/campusfix_mysql_export.sql` in InfinityFree phpMyAdmin.

Then verify:

```text
https://YOUR_API_SITE.infinityfreeapp.com/api/health
```

Expected response:

```json
{"status":"ok","app":"CampusFix"}
```

## 3. Build The Flutter Web Package

For a one-site deployment, build Flutter with the same site's API URL:

```powershell
.\tools\build_infinityfree_web.ps1 `
  -ApiBase "https://YOUR_SITE.infinityfreeapp.com/api"
```

The output is:

```text
build/infinityfree/campusfix-infinityfree-web.zip
build/infinityfree/web/
```

For a one-site deployment, upload the contents of `build/infinityfree/web` into the existing Laravel `htdocs/public` folder. Keep `public/index.php` and `public/.htaccess` in place for the Laravel API.

For a two-site deployment, upload the contents of `build/infinityfree/web` to the frontend site's `htdocs` folder.

## 4. Notes

- If using one site, keep Laravel in `htdocs` and Flutter web files in `htdocs/public`.
- If using two sites, keep the Laravel API and Flutter web app on separate InfinityFree sites/subdomains.
- Do not upload `node_modules`.
- The backend package includes `vendor`, because InfinityFree does not run Composer for you.
- If you do not pass database settings to the backend package script, fill `htdocs/.env.infinityfree.example`, rename it to `.env`, then upload it.
- Cloudinary is recommended for report photos. Without Cloudinary, photos are stored as data URLs in MySQL, which is only suitable for light demos.
