# Specz.co — Release Candidate Gate & Evidence Register

**Version**: `v1.0.0-rc1`  
**Target Release**: Production Staged Beta  
**Backend Test Status**: 🟢 **33 / 33 PASSED (100%)**  
**Overall Readiness Posture**: 🟢 Backend Hardened / 🟠 Release Candidate Verification  

---

## 1. Severity & Release Gate Rules

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RELEASE GATE RULES                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🔴 P0 (Release Blocker) : Zero launch if ANY test fails. Stop and fix.     │
│ 🟠 P1 (Pre-Release)     : Must be green before public App/Play Store.       │
│ 🟡 P2 (Beta Tolerant)   : Cosmetic / non-blocking; can survive beta.        │
│ 🟢 P3 (Post-Launch)     : Backlog for future sprints.                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

> **Mandatory Rule**: A P2 bug cannot delay a P0 fix, and a P0 bug cannot be hidden by a successful feature demo. Every manual verification step must record verifiable evidence (screenshot, request ID, DB query, or screen recording).

---

## 2. Evidence Collection Matrix

### A. Authentication & Multi-Tenant Security (P0)

| Test ID | Test Case Description | Environment | Expected Result | Evidence Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AUTH-01` | Google Sign-In New User | Android / iOS | New user created in SQLite & backend DB with Free tier | Screen recording + User ID | ⬜ Pending |
| `AUTH-02` | Session Restore on Restart | Physical Device | App auto-logs into saved SQLite user without re-auth | App restart video | ⬜ Pending |
| `AUTH-03` | Account Deletion Cascade | Physical Device | All profiles, prescriptions, drops, and secure storage wiped | SQLite DB query + Logout screen | ⬜ Pending |
| `AUTH-04` | Token Refresh Rotation | Network Mock | 401 response triggers `/auth/refresh` and transparently retries | `X-Request-ID` API log | 🟢 Verified (`test_auth.py`) |
| `SEC-01` | Cross-Tenant Profile IDOR | API Test | User B cannot GET/PATCH/DELETE User A's profile (403/404) | Pytest result | 🟢 Verified (`test_security_multitenant.py`) |
| `SEC-02` | Cross-Tenant Prescription IDOR | API Test | User B cannot view or inject prescriptions in User A's profile | Pytest result | 🟢 Verified (`test_security_multitenant.py`) |
| `SEC-03` | Cross-Tenant Medication IDOR | API Test | User B cannot view or delete eye drops in User A's profile | Pytest result | 🟢 Verified (`test_security_multitenant.py`) |

---

### B. Offline-First Synchronization & Data Integrity (P0)

| Test ID | Test Case Description | Environment | Expected Result | Evidence Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `SYNC-01` | Airplane Mode Record Creation | Physical Device | Profile, prescription, and eye drop created locally in SQLite | Screen recording in Airplane mode | ⬜ Pending |
| `SYNC-02` | Reconnection Queue Flush | Physical Device | Enqueued mutations push to `/api/v1/sync/push` with zero duplicates | Backend DB rows count == local count | ⬜ Pending |
| `SYNC-03` | App Kill During Active Sync | Physical Device | Unfinished sync queue preserved; retried on reopen cleanly | SQLite `sync_queue` table inspection | ⬜ Pending |
| `SYNC-04` | High-Volume Batch (30+ Ops) | API Test | 30 queued mutations processed idempotently with duplicate suppression | Pytest result | 🟢 Verified (`test_sync_deep.py`) |
| `SYNC-05` | Null Cyl vs 0.00 Integrity | API & SQLite | Spherical-only prescription preserves `CYL = NULL` across sync | DB assertion query | 🟢 Verified (`test_prescriptions.py`) |

---

### C. Subscriptions, Payments & Entitlements (P0)

| Test ID | Test Case Description | Environment | Expected Result | Evidence Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `PAY-01` | Razorpay Order Creation | API Test | Backend returns valid `order_id`, `amount`, and `key_id` | API response payload | 🟢 Verified (`test_subscriptions.py`) |
| `PAY-02` | HMAC Signature Verification | API Test | Authentic HMAC signature activates Plus tier (`max_profiles=5`) | Pytest result | 🟢 Verified (`test_payments_deep.py`) |
| `PAY-03` | Forged Signature Rejection | API Test | Invalid or tampered signature rejected with 400 Bad Request | Pytest result | 🟢 Verified (`test_payments_deep.py`) |
| `PAY-04` | Duplicate Verification Idempotency | API Test | Submitting same valid payment twice yields identical active status | Pytest result | 🟢 Verified (`test_payments_deep.py`) |
| `PAY-05` | Real Device Razorpay Checkout | Android Test Mode | Razorpay checkout sheet opens, succeeds, and upgrades profile limit | Razorpay Payment ID + App screenshot | ⬜ Pending |
| `PAY-06` | Expired Subscription Behavior | SQLite & API | Expired Plus transitions to read-only; all 5 existing profiles preserved | SQLite user plan == 'free' + UI check | ⬜ Pending |

---

### D. Physical Hardware & Alarms (P1)

| Test ID | Test Case Description | Platform | Expected Result | Evidence Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `NOTIF-AND-01` | Foreground Drop Reminder | Android 12+ | Heads-up banner with custom chime sound and vibration | Screen recording with audio | ⬜ Pending |
| `NOTIF-AND-02` | Locked Phone Insistent Alarm | Android 12+ | Full-screen alarm displays with `TAKE`, `SNOOZE` (15m), `SKIP` | Lock screen photo / video | ⬜ Pending |
| `NOTIF-AND-03` | App Terminated Alarm | Android 12+ | Alarm rings at scheduled time even if app was swiped away | Device test log | ⬜ Pending |
| `NOTIF-AND-04` | Do Not Disturb (DND) Behavior | Android 12+ | Channel priority adheres to user's medical alarm overrides | Android settings screenshot | ⬜ Pending |
| `NOTIF-IOS-01` | iOS Local Notification | iOS 16+ | Notification banner triggers with action buttons | iOS device screenshot | ⬜ Pending |
| `NOTIF-LOG-01` | Dose Logging Adherence | Physical Device | Tapping `TAKE` logs dose in SQLite and recalculates adherence % | SQLite `medication_logs` query | ⬜ Pending |

---

### E. OCR, AI Consultation & PDF Generation (P1)

| Test ID | Test Case Description | Environment | Expected Result | Evidence Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `OCR-01` | Clear Paper Prescription Scan | Physical Camera | Accurately extracts `SPH`, `CYL`, `AXIS`, `PD`, and doctor name | Photo + parsed dialog screenshot | ⬜ Pending |
| `OCR-02` | Glare / Crumpled Paper Scan | Physical Camera | Low-confidence fields highlighted; user easily edits in modal | Modal screenshot with edits | ⬜ Pending |
| `OCR-03` | Offline / Backend Down Fallback | Flight Mode | Graceful fallback banner displayed; manual entry completely unimpeded | Fallback UI screenshot | ⬜ Pending |
| `SCORE-01` | Vision Care Score Calculation | Algorithm Test | 7 factors strictly bounded (0-100); deterministic boundaries | Pytest result | 🟢 Verified (`test_scores_deterministic.py`) |
| `PDF-01` | Multilingual Export (English) | Device PDF Viewer | Clean typography, table alignment, doctor questions snapshot | Exported `.pdf` file | ⬜ Pending |
| `PDF-02` | Multilingual Export (Hindi / தமிழ்) | Device PDF Viewer | Indic scripts render perfectly without missing character boxes (`□`) | Exported Hindi / Tamil `.pdf` | ⬜ Pending |
| `PDF-03` | Free Tier PDF Export Gating | Physical Device | Free user sees upgrade prompt; download/print buttons locked | Dialog screenshot | ⬜ Pending |

---

### F. Production Infrastructure & Resilience (P1)

| Test ID | Test Case Description | Target System | Expected Result | Evidence Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `DB-01` | Live PostgreSQL 15 Parity Run | PostgreSQL Staging | All 33 tests pass against PostgreSQL engine with zero dialect errors | Pytest PostgreSQL output | ⬜ Pending |
| `DB-02` | Alembic Migration & Rollback | Database CLI | `alembic upgrade head` ➔ `alembic downgrade -1` runs cleanly | Terminal output log | ⬜ Pending |
| `DB-03` | Backup & Disaster Recovery Drill | `pg_dump` / `pg_restore` | Full database restored to empty instance; `/health/ready` == ok | Restoration log + probe output | ⬜ Pending |
| `REDIS-01` | Distributed Rate Limiting | Redis Instance | Auth (5/min), OCR (10/min), Sync (60/min) enforced across multiple instances | Rate limit 429 response log | ⬜ Pending |
| `REDIS-02` | Redis Outage Hybrid Fallback | Simulated Outage | Reads fallback to in-memory limits; sensitive routes fail conservative | API access log | ⬜ Pending |
| `LOAD-01` | Concurrency Baseline (10-100) | Locust / K6 | Normal endpoints maintain P95 latency < 150ms; 0% 5xx errors | Load report summary | ⬜ Pending |
| `LOAD-02` | OCR Concurrency Isolation | Locust / K6 | 30 simultaneous OCR requests do not block Auth or Profile APIs | Concurrency test report | ⬜ Pending |

---

## 3. Emergency Feature-Flag Runbook

If any third-party provider or subsystem encounters an outage, adjust the environment variables on the backend without requiring a new mobile app release:

```bash
# 1. OCR Gateway Outage (Gemini Vision down)
FLAG_OCR_ENABLED=false
# Impact: App seamlessly prompts manual prescription entry without crashing.

# 2. AI Consultation Outage
FLAG_AI_ENABLED=false
# Impact: App shows standard clinical preparation checklist.

# 3. PDF Generation Font Service Outage
FLAG_PDF_EXPORT_ENABLED=false
# Impact: App provides on-screen summary cards.

# 4. Payment Gateway Outage (Razorpay maintenance)
FLAG_PLUS_ENABLED=false
# Impact: Upgrade buttons display maintenance message; existing Plus users unaffected.

# 5. Full Maintenance Mode
FLAG_MAINTENANCE_MODE=true
# Impact: App displays polite maintenance screen with retry button.
```

---

## 4. Beta Testing Feedback Taxonomy

When distributing `v1.0.0-rc1` to internal (5 users) and beta (20 users) cohorts, categorize all user feedback using this standardized schema:

```text
[CATEGORY] - [SEVERITY] - [DESCRIPTION] - [REFERENCE ID]
Example: SYNC - P0 - Offline dose log duplicated after airplane mode toggle - Ref: req_9a8f12c
```

### Classification Categories:
1. `CRASH`: App unhandled exception or termination.
2. `DATA_LOSS`: Missing prescription, medication, or profile.
3. `DATA_DUPLICATION`: Duplicate database entries.
4. `AUTH`: Sign-in, sign-out, or session restore issues.
5. `SYNC`: Offline queue or network sync issues.
6. `PAYMENT`: Razorpay checkout or entitlement delay.
7. `NOTIFICATION`: Alarm did not fire or action failed.
8. `OCR`: Text extraction accuracy or camera issue.
9. `PDF`: Layout, typography, or sharing issue.
10. `UI_PERFORMANCE`: Visual lag, contrast, or responsiveness.
