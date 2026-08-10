# SPECZ.CO V2 — TESTING SPECIFICATION

## Test Suite Structure

1. **Unit Tests (`test/unit_test.dart`)**
   - Vision Care Score V2 calculation (transparent baseline, component breakdown, up-to-date prescription scoring).
   - OCR Extraction & Confidence Score parsing.
   - Prescription missing SPH/CYL validation.
   - UserModel tier capacity tests (Free 1 profile vs Plus 5 profiles).

2. **Widget Tests (`test/widget_test.dart`)**
   - `EyeHealthScoreCard` score rendering, score label, and reasoning text display.
   - Navigation & profile switcher widget rendering.

## Executing Automated Tests
Run unit and widget tests:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

Build debug APK:
```bash
flutter build apk --debug
```
