# SPECZ.CO V2 — REST API SPECIFICATION

## Authentication & Users
- `POST /auth/login`: Authenticate user session.
- `POST /auth/logout`: Invalidate active access tokens.
- `GET /users/me`: Fetch authenticated user profile and subscription tier.

## Profiles
- `GET /profiles`: List profiles belonging to authenticated user.
- `POST /profiles`: Create profile (enforces tier capacity: 1 free / 5 plus).
- `PATCH /profiles/:id`: Update profile info.
- `DELETE /profiles/:id`: Cascade delete profile and related records.

## Prescriptions & Medical Records
- `GET /profiles/:id/prescriptions`: Retrieve historical prescriptions.
- `POST /profiles/:id/prescriptions`: Create confirmed prescription record with normalized eye values.
- `POST /ai/ocr/extract`: Extract prescription values with confidence scoring.

## Medications & Alarms
- `GET /profiles/:id/medications`: List active eye drops and medication schedules.
- `POST /profiles/:id/medications`: Create new medication & schedules.
- `POST /medications/:id/log`: Log dose status (`TAKEN`, `SNOOZED`, `SKIPPED`, `MISSED`).

## Subscriptions & Payments
- `GET /subscription`: Get active subscription status.
- `POST /subscription/order`: Create Razorpay order on backend server.
- `POST /subscription/webhook`: Server-to-server webhook callback confirming payment state.
