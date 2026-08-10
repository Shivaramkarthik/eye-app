# SPECZ.CO V2 — ARCHITECTURE SPECIFICATION

## Overview
Specz.co is a local-first digital eye-care companion built with Flutter 3.x, Dart 3.x, Material 3, and SQLite (`sqflite`). It provides family profile eye care management, prescription handling with OCR extraction & confirmation, OS-level medication alarms, explainable Vision Care Scoring, server-verifiable entitlement rules, offline PDF generation, and local data security.

---

## Directory & File Responsibilities

```
lib/
├── main.dart                      # Application entry point, theme & route setup
├── app.dart                       # Global MaterialApp & configuration
├── core/
│   ├── constants/                 # App colors, sizes, and strings
│   ├── errors/                    # Centralized error exceptions
│   ├── routing/                   # Route transitions & navigation handlers
│   └── security/                  # Encryption & secure key storage
├── data/
│   ├── local/
│   │   ├── database_service.dart  # SQLite database instance & initialization
│   │   ├── migration_manager.dart # Schema V2 migration & transaction safety
│   │   └── dao/                   # Isolated Data Access Objects
│   │       ├── user_dao.dart
│   │       ├── profile_dao.dart
│   │       ├── prescription_dao.dart
│   │       ├── medication_dao.dart
│   │       ├── score_dao.dart
│   │       ├── report_dao.dart
│   │       └── subscription_dao.dart
│   └── repositories/
│       ├── profile_repository.dart
│       ├── prescription_repository.dart
│       ├── medication_repository.dart
│       ├── score_repository.dart
│       └── subscription_repository.dart
├── models/
│   ├── user_model.dart
│   ├── profile_model.dart
│   ├── prescription_model.dart
│   ├── prescription_eye_value_model.dart
│   ├── medication_model.dart
│   ├── medication_schedule_model.dart
│   ├── medication_log_model.dart
│   ├── eye_care_score_model.dart
│   ├── ai_summary_model.dart
│   ├── doctor_question_model.dart
│   ├── report_model.dart
│   └── subscription_model.dart
├── services/
│   ├── notification_service.dart  # flutter_local_notifications engine
│   ├── notification_scheduler.dart# OS alarm scheduler & reschedule manager
│   ├── ai_ocr_service.dart        # Vision OCR extraction & score engine
│   ├── pdf_service.dart           # Offline PDF report builder
│   ├── entitlement_service.dart   # Subscription profile limits (1 free / 5 plus)
│   ├── razorpay_service.dart      # Payment gateway checkout
│   ├── audio_haptic_service.dart   # Audio/vibration alarm feedback
│   └── i18n_service.dart          # Multilingual translation dictionary
├── widgets/                       # Reusable visual components & dialogs
└── l10n/                          # Localization string catalogs
```

---

## Architecture Principles
1. **Layer Separation**: No UI screen executes SQL queries directly. Screens delegate to Controllers/Repositories, which query DAOs over SQLite.
2. **OS-Level Alarm Engine**: Medication reminders use `flutter_local_notifications` with timezone support (`timezone` package). Alarms trigger even when the application is backgrounded or killed.
3. **Normalized Relational Database**: Arrays (symptoms, medication schedules, logs, eye values) are stored in normalized tables with strict foreign keys (`ON DELETE CASCADE`).
4. **Human Review & Prescriptions**: Missing CYL is stored as `NULL` / `MISSING` and never silently defaults to `0.0`. OCR extraction presents a structured confirmation dialog prior to saving.
5. **Vision Care Score (0–100)**: Component-based care index (Prescription completeness, stability, adherence, follow-up recency, profile completeness, care routine consistency, history quality) with version tracking (`algorithm_version: 2`) and non-diagnostic disclaimers.
