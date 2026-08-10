# Specz.co — Digital Eye-Care Companion (V2 Production Architecture)

Specz.co is a cross-platform digital eye-care companion built with Flutter 3.x, Dart 3.x, SQLite, and Material 3.

## Features
- **Family Profiles**: Manage eye health records for Self, Spouse, Child, Parent, and Others.
- **Prescription OCR & Human Confirmation**: Camera scan, field confidence scoring (`✓ Confirmed`, `⚠ Missing`, `✎ Manual`), explicit `CYL` missing detection, and prescription comparison across time.
- **OS-Level Eye Drop Alarms**: Reliable background reminders using `flutter_local_notifications` with `TAKE`, `SNOOZE`, and `SKIP` actions.
- **Vision Care Score (0–100)**: Transparent, explainable care index with component scores (Completeness, Stability, Adherence, Recency, History Quality) and non-diagnostic disclaimers.
- **Offline PDF Reports**: Immutable PDF report snapshots using Google Fonts / Helvetica fallback.
- **Server-Verifiable Entitlements**: Free tier (1 profile), Plus tier (up to 5 profiles); subscription expiry preserves existing data.
- **Local Security & Account Deletion**: Query ownership checks (`user_id` + `profile_id`), session security, and account deletion with complete data wipe.

## Installation & Running

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run Tests**:
   ```bash
   flutter test
   ```

3. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```

4. **Build Debug Application**:
   ```bash
   flutter build apk --debug
   ```

## Documentation
- [ARCHITECTURE.md](file:///c:/Users/shiva/OneDrive/Desktop/eye%20app/ARCHITECTURE.md)
- [DATABASE.md](file:///c:/Users/shiva/OneDrive/Desktop/eye%20app/DATABASE.md)
- [SECURITY.md](file:///c:/Users/shiva/OneDrive/Desktop/eye%20app/SECURITY.md)
- [API.md](file:///c:/Users/shiva/OneDrive/Desktop/eye%20app/API.md)
- [TESTING.md](file:///c:/Users/shiva/OneDrive/Desktop/eye%20app/TESTING.md)
- [CHANGELOG.md](file:///c:/Users/shiva/OneDrive/Desktop/eye%20app/CHANGELOG.md)
