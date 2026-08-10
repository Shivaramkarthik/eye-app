# SPECZ.CO V2 — REST API SPECIFICATION (`/api/v1/`)

## 1. System Health
* `GET /health`: Basic liveness check.
* `GET /health/ready`: Database dependency readiness probe.

## 2. Authentication & Security (`/api/v1/auth`)
* `POST /auth/register`: Register new user account.
* `POST /auth/login`: Authenticate user and issue JWT access + refresh tokens.
* `POST /auth/refresh`: Rotate refresh token and issue new token pair.
* `POST /auth/logout`: Invalidate active session.
* `GET  /auth/me`: Get authenticated user profile.
* `POST /auth/forgot-password`: User enumeration-safe password reset trigger.
* `DELETE /auth/account`: Soft-delete account and invalidate state.

## 3. Profiles (`/api/v1/profiles`)
* `GET    /profiles`: List profiles belonging to authenticated user.
* `POST   /profiles`: Create profile (Enforces server entitlement limit: 1 Free / 5 Plus).
* `GET    /profiles/:id`: Get profile details (IDOR protected).
* `PATCH  /profiles/:id`: Update profile info.
* `DELETE /profiles/:id`: Delete profile.

## 4. Prescriptions (`/api/v1`)
* `GET  /profiles/:id/prescriptions`: Retrieve optical prescriptions.
* `POST /profiles/:id/prescriptions`: Create confirmed prescription with normalized eye values (Preserves `CYL = NULL`).
* `DELETE /prescriptions/:id`: Delete prescription.

## 5. Medications (`/api/v1`)
* `GET    /profiles/:id/medications`: List eye drop catalog & schedules.
* `POST   /profiles/:id/medications`: Create new medication & schedules.
* `DELETE /medications/:id`: Delete medication.

## 6. Offline Cloud Synchronization (`/api/v1/sync`)
* `POST /sync/push`: Push enqueued client operations idempotently (`operation_id` deduplicated).
* `GET  /sync/pull`: Pull cloud user state down to device.

## 7. Subscriptions & Payments (`/api/v1/subscriptions` & `/webhooks`)
* `GET  /subscriptions/entitlements/me`: Get server-authoritative plan features & limits.
* `POST /subscriptions/create-order`: Create Razorpay order on backend server.
* `POST /subscriptions/verify-payment`: Verify payment signature and activate Plus entitlement.
* `POST /webhooks/razorpay`: Server-to-server webhook listener with HMAC verification.

## 8. AI & OCR (`/api/v1/ai`)
* `POST /ai/ocr-prescription`: Extract optical values with confidence scores (Requires user confirmation).
* `POST /ai/doctor-questions`: Generate clinical questions for doctor appointments (Informational only).
* `POST /ai/summary`: Generate non-diagnostic vision care routine summary.

## 9. Reports & Private Storage (`/api/v1/reports`)
* `GET  /reports/upload-url`: Generate pre-signed S3 upload URL.
* `POST /reports`: Save report metadata snapshot.
