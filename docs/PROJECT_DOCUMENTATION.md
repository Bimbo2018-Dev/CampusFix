# CampusFix Project Documentation

## Overview

CampusFix is a responsive campus issue reporting system for Students, Teachers, and Admins. The app is intended for school maintenance, IT, clinic, lost and found, and facility workflows.

## Architecture

- Frontend: Flutter, Dart, Material 3, ChangeNotifier state management.
- Backend: Laravel REST API, Laravel Sanctum authentication.
- Database: MySQL with relational foreign keys.
- PWA: Flutter web manifest and service worker support.
- Downloadable app: Android APK build output and PWA install support.

## Main Modules

- Authentication: registration, login, logout, role-based demo accounts.
- Reports: create, list, detail, status update, delete.
- Notes: user follow-up, teacher notes, admin notes.
- Teacher validation: marks student reports reviewed/validated.
- Admin dashboard: analytics summaries, urgent list, user list.
- Notifications: generated local notification-style report updates.

## Database Deliverables

- Migrations: `backend/database/migrations`
- Seed data: `backend/database/seeders/DatabaseSeeder.php`
- SQL export: `database/sql/campusfix_mysql_export.sql`
- ERD: `docs/ERD.md`

## API Deliverables

See `docs/API.md` for route list, auth requirements, and sample payloads.

## Member Contributions

| Member | Contribution |
| --- | --- |
| Developer 1 | Flutter UI, responsive layouts, PWA configuration |
| Developer 2 | Laravel API, Sanctum authentication, MySQL migrations |
| Developer 3 | Documentation, SRS, user stories, ERD, testing |

Update this table with the actual group member names before submission.

## Verification Checklist

- Flutter analyze passes.
- Flutter tests pass.
- Laravel tests pass.
- Laravel API health endpoint responds.
- Admin login returns a token.
- Authenticated report list returns seeded reports.
- MySQL contains users, reports, and report notes.
