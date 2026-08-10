# CHANGELOG — SPECZ.CO V2

## [2.0.0] - 2026-08-10

### Added
- OS-level local notification scheduling using `flutter_local_notifications` and `timezone` for reliable eye-drop alarms (`TAKE`, `SNOOZE`, `SKIP`).
- Database Schema V2 with normalized tables (`users`, `profiles`, `profile_symptoms`, `prescriptions`, `prescription_eye_values`, `medications`, `medication_schedules`, `medication_logs`, `eye_care_scores`, `ai_summaries`, `doctor_questions`, `reports`, `subscriptions`).
- Transactional `DatabaseMigrationManager` for seamless V1 → V2 migration preserving user history.
- Prescription Confirmation modal (`PrescriptionConfirmationDialog`) displaying field confidence scores (`✓ Confirmed`, `⚠ Missing`, `✎ Manual`) and medical disclaimers before saving.
- Redesigned Vision Care Score (0–100) with transparent component weights, algorithm versioning (`algorithm_version: 2`), detailed breakdown explanations, and non-diagnostic disclaimers.
- Entitlement rules enforcement: Free (1 profile), Plus (up to 5 profiles); subscription expiration preserves existing profiles/data.
- Account Deletion flow with double confirmation modal, cascading local data wipe, and session invalidation.

### Changed
- Prescriptions now store `CYL` as nullable (`double?`) with status flags (`CONFIRMED`, `MANUAL`, `OCR_EXTRACTED`, `UNCERTAIN`, `MISSING`), eliminating silent `CYL=0.00` conversion bugs.
- Database access refactored into isolated DAOs (`UserDao`, `ProfileDao`, `PrescriptionDao`, `MedicationDao`, `ScoreDao`, `ReportDao`, `SubscriptionDao`).
- Replaced background process `Timer.periodic` with platform-native OS notification scheduler.
