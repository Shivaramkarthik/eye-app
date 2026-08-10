# SPECZ.CO V2 — DATABASE SPECIFICATION

Specz.co utilizes a dual-database architecture:
1. **Local SQLite (`sqflite`)**: On-device primary database storing local-first user records and a persistent `sync_queue`.
2. **Cloud PostgreSQL 15**: Central relational database managed via Alembic migrations supporting cloud sync, entitlements, and multi-tenant security.

---

## Schema V2 Tables (SQLite & PostgreSQL Dual Parity)

1. **`users`**: Account identity & subscription state.
2. **`profiles`**: Individual & family profiles linked to user (`user_id`).
3. **`profile_symptoms`**: Normalized eye symptoms per profile (`profile_id`).
4. **`prescriptions`**: Optical metadata & OCR confidence (`profile_id`, `user_id`).
5. **`prescription_eye_values`**: Normalized OD/OS SPH, CYL, Axis. `CYL = NULL` preserved.
6. **`medications`**: Eye drops & medication catalog (`profile_id`, `user_id`).
7. **`medication_schedules`**: Reminder times & tone settings (`medication_id`).
8. **`medication_logs`**: Dose tracking logs (`TAKEN`, `SNOOZED`, `SKIPPED`, `MISSED`).
9. **`eye_care_scores`**: Vision Care Index breakdown (0-100), `algorithm_version: 2`.
10. **`reports`**: PDF report metadata & snapshots (`profile_id`, `user_id`).
11. **`subscriptions`**: Razorpay subscription tracking & payment verification state.
12. **`sync_records`**: Idempotent cloud sync operation tracking (`operation_id` UNIQUE).
13. **`sync_queue`** (SQLite local only): Enqueued client operations pending push to cloud.
14. **`analytics_events`**: Privacy-safe event tracking (NO medical data).
15. **`audit_logs`**: Security audit log events (logins, logouts, payment verifications).
