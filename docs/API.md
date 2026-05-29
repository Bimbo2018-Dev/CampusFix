# CampusFix REST API

Base URL for local development:

```text
http://127.0.0.1:8001/api
```

Use `Authorization: Bearer <token>` for protected endpoints.

## Public Endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | `/health` | API health check |
| GET | `/meta` | Categories, priorities, and statuses |
| POST | `/auth/login` | Log in and receive Sanctum token |
| POST | `/auth/register` | Register and receive Sanctum token |

## Protected Endpoints

| Method | Endpoint | Role Access | Purpose |
| --- | --- | --- | --- |
| GET | `/user` | Student, Teacher, Admin | Current user profile |
| POST | `/auth/logout` | Student, Teacher, Admin | Revoke current token |
| GET | `/reports` | Role-filtered | List reports visible to current user |
| POST | `/reports` | Student, Teacher, Admin | Create report |
| GET | `/reports/{external_id}` | Role-filtered | Show report details |
| PATCH | `/reports/{external_id}` | Admin for status | Update report fields/status |
| DELETE | `/reports/{external_id}` | Admin | Delete report |
| POST | `/reports/{external_id}/notes` | Owner, Teacher, Admin | Add report note |
| POST | `/reports/{external_id}/validate` | Teacher, Admin | Mark report teacher-validated |
| GET | `/users` | Admin | List system users |

## Sample Login

```json
{
  "email": "admin@campusfix.app",
  "password": "admin123",
  "role": "Admin"
}
```

## Sample Report Create

```json
{
  "title": "Projector not working",
  "description": "The projector powers on but does not display laptop input.",
  "category": "IT Concern",
  "location": "AVR 1",
  "priority": "High",
  "imagePath": null
}
```
