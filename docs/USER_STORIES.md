# CampusFix User Stories and Product Backlog

## Epics

1. Authentication and Role Access
2. Report Submission and Tracking
3. Teacher Validation
4. Admin Management
5. Notifications, Profile, and PWA

## Backlog

| ID | Epic | User Story | Acceptance Criteria | MoSCoW | Points |
| --- | --- | --- | --- | --- | --- |
| US-01 | Authentication | As a student, I want to log in with my school account so that I can access my reports. | Given valid student credentials, when I log in, then I see the student dashboard. | Must | 3 |
| US-02 | Authentication | As a teacher, I want to log in with a teacher role so that I can validate reports. | Given valid teacher credentials, when I log in, then I see teacher tools. | Must | 3 |
| US-03 | Authentication | As an admin, I want token-based API login so that report management is protected. | Given valid admin credentials, when I log in, then the API returns a Sanctum token. | Must | 5 |
| US-04 | Authentication | As a new user, I want to register with a role so that I can start using CampusFix. | Given valid registration details, when I submit, then an account is created and I am logged in. | Must | 5 |
| US-05 | Report Submission | As a student, I want to submit a campus issue so that maintenance can respond. | Given required report fields, when I submit, then the report is stored through the API. | Must | 5 |
| US-06 | Report Submission | As a user, I want to attach a photo so that the issue is easier to verify. | Given a selected image, when I submit, then the image data is saved with the report. | Should | 5 |
| US-07 | Report Tracking | As a student, I want to view my own reports so that I can monitor progress. | Given I am logged in as student, when I open reports, then only my reports are shown. | Must | 3 |
| US-08 | Report Tracking | As a user, I want search and filters so that I can find reports quickly. | Given reports exist, when I search/filter, then matching reports are displayed. | Must | 3 |
| US-09 | Report Tracking | As a user, I want to open report details so that I can review full information. | Given a report card/table row, when I open it, then title, description, status, priority, and notes are shown. | Must | 3 |
| US-10 | Teacher Validation | As a teacher, I want to view student reports so that I can validate classroom concerns. | Given I am a teacher, when I open dashboard, then student reports are visible. | Must | 5 |
| US-11 | Teacher Validation | As a teacher, I want to validate a student report so that admins know it was reviewed. | Given an unvalidated student report, when I validate it, then the report is marked validated. | Must | 5 |
| US-12 | Teacher Validation | As a teacher, I want to add notes so that I can explain my validation decision. | Given a report I can access, when I add a note, then it appears in the note timeline. | Should | 3 |
| US-13 | Admin Management | As an admin, I want to view all reports so that I can manage campus operations. | Given I am admin, when I open reports, then all reports are visible. | Must | 5 |
| US-14 | Admin Management | As an admin, I want to update report status so that users know progress. | Given an existing report, when I set a status, then the API stores the new status. | Must | 5 |
| US-15 | Admin Management | As an admin, I want to delete invalid reports so that the system stays clean. | Given a report is invalid, when I confirm delete, then it is removed from the database. | Should | 3 |
| US-16 | Admin Management | As an admin, I want dashboard analytics so that urgent issues are easy to prioritize. | Given reports exist, when I open admin dashboard, then status/category/urgent summaries are shown. | Should | 5 |
| US-17 | Notifications | As a user, I want notifications so that I can see report updates quickly. | Given report statuses change, when I open notifications, then update messages appear. | Could | 2 |
| US-18 | PWA | As a mobile user, I want to install the web app so that I can open CampusFix like an app. | Given I open the web app in a supported browser, when I install it, then it launches standalone. | Should | 3 |

## Priority Summary

- Must: login, registration, API auth, report CRUD, role visibility, teacher validation, admin status updates.
- Should: image evidence, notes, admin delete, analytics, PWA.
- Could: richer notifications and future push notification support.
- Won't for prototype: payment features, real-time chat, production email workflows.
