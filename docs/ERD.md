# CampusFix ERD

## Logical ERD

```mermaid
erDiagram
  USER ||--o{ REPORT : submits
  USER ||--o{ REPORT_NOTE : writes
  REPORT ||--o{ REPORT_NOTE : contains
  REPORT_CATEGORY ||--o{ REPORT : classifies
  REPORT_PRIORITY ||--o{ REPORT : prioritizes
  REPORT_STATUS ||--o{ REPORT : tracks
```

## Physical ERD

```mermaid
erDiagram
  users {
    bigint id PK
    varchar name
    varchar email UK
    varchar password
    varchar role
    varchar department
    varchar avatar_text
    timestamp created_at
    timestamp updated_at
  }
  reports {
    bigint id PK
    varchar external_id UK
    bigint user_id FK
    bigint category_id FK
    bigint priority_id FK
    bigint status_id FK
    varchar title
    text description
    varchar location
    longtext image_path
    boolean is_validated_by_teacher
    varchar assigned_to
    timestamp created_at
    timestamp updated_at
  }
  report_notes {
    bigint id PK
    bigint report_id FK
    bigint user_id FK
    text message
    timestamp created_at
    timestamp updated_at
  }
  report_categories {
    bigint id PK
    varchar name UK
    varchar description
  }
  report_priorities {
    bigint id PK
    varchar name UK
    tinyint weight
  }
  report_statuses {
    bigint id PK
    varchar name UK
    tinyint sort_order
  }

  users ||--o{ reports : user_id
  users ||--o{ report_notes : user_id
  reports ||--o{ report_notes : report_id
  report_categories ||--o{ reports : category_id
  report_priorities ||--o{ reports : priority_id
  report_statuses ||--o{ reports : status_id
```

## Table Relationship Notes

- `reports.user_id` references the submitting user.
- `report_notes.report_id` references the related report.
- `report_notes.user_id` references the note author and is nullable so notes can remain if an author is removed.
- `reports.category_id`, `reports.priority_id`, and `reports.status_id` reference lookup tables.
