# SPECZ.CO V2 — SECURITY SPECIFICATION

## 1. Authentication & Token Management
* Mobile JWT tokens stored in platform-encrypted storage using `flutter_secure_storage`.
* Short-lived access tokens (30 minutes) + rotating refresh tokens (30 days).
* Passwords hashed using Argon2 / Bcrypt. Plaintext passwords never stored or logged.

## 2. Strict IDOR Multi-Tenant Protection
* Every API endpoint enforces user ownership checks deriving `user_id` strictly from JWT token:
  ```sql
  SELECT * FROM prescriptions WHERE profile_id = :id AND user_id = :authenticated_user_id;
  ```
* User A cannot view, mutate, or delete User B's profiles, prescriptions, medications, scores, or reports.

## 3. Server-Authoritative Entitlements
* Plan capacity limits (1 Free / 5 Plus) enforced server-side. Local variable tampering cannot unlock premium limits without valid Razorpay HMAC signature verification.

## 4. Webhook & Payment Verification
* All Razorpay payments verified using HMAC-SHA256 signature verification.
* Razorpay Webhooks verified with `RAZORPAY_WEBHOOK_SECRET` and processed idempotently.

## 5. Medical Safety & Privacy Boundaries
* AI outputs explicitly disclaimed as non-diagnostic informational summaries.
* Cloud OCR outputs require human confirmation prior to database save.
* Medical data, email, phone, and tokens excluded from analytics logs.
* Private S3 object storage uses pre-signed upload/download URLs with strict expiration timeouts.
