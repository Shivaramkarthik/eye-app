# SPECZ.CO V2 — SECURITY SPECIFICATION

## Security Architecture & Best Practices

1. **Authentication Token Management**
   - Active user session details are stored securely using platform secure storage (`flutter_secure_storage`).
   - Plain text `SharedPreferences` is limited strictly to UI preferences.

2. **Data Access & Query Ownership Enforcements**
   - Every DAOs operation enforces multi-tenant ownership checks:
     ```sql
     SELECT * FROM prescriptions WHERE profile_id = ? AND user_id = ?
     ```
   - User A cannot access or mutate Profile B records.

3. **Local Medical Data Protection**
   - Temporary prescription images are stored in application-private directories and deleted immediately after processing when no longer required.
   - Sensitive medical values (SPH, CYL, diagnosis summaries) are excluded from release debug logs.

4. **Account Deletion Flow**
   - Confirmation modal verifies intent.
   - Cascading local wipe purges all profiles, prescriptions, eye drop schedules, logs, scores, and reports.
   - Invalidates local session tokens.

5. **Entitlement Protection**
   - Client applications consume server entitlement state (`subscriptions` table).
   - Local variable tampering (e.g. `plan = "plus"`) does not grant premium profile limits without valid subscription record verification.
