# SPECZ.CO V2 — DATABASE SPECIFICATION

## Schema V2 Tables

### 1. `users`
- `id` TEXT PRIMARY KEY
- `email` TEXT NOT NULL
- `phone` TEXT
- `first_name` TEXT
- `last_name` TEXT
- `display_name` TEXT
- `plan` TEXT NOT NULL DEFAULT 'free'
- `account_status` TEXT NOT NULL DEFAULT 'ACTIVE'
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- `deleted_at` TEXT

### 2. `profiles`
- `id` TEXT PRIMARY KEY
- `user_id` TEXT NOT NULL FOREIGN KEY -> users(id) ON DELETE CASCADE
- `name` TEXT NOT NULL
- `dob` TEXT NOT NULL
- `gender` TEXT NOT NULL
- `relationship` TEXT NOT NULL DEFAULT 'Self'
- `profile_type` TEXT NOT NULL DEFAULT 'Adult'
- `prescription_type` TEXT
- `blurred_vision_type` TEXT
- `archived` INTEGER NOT NULL DEFAULT 0
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
- `deleted_at` TEXT

### 3. `profile_symptoms`
- `id` TEXT PRIMARY KEY
- `profile_id` TEXT NOT NULL FOREIGN KEY -> profiles(id) ON DELETE CASCADE
- `symptom` TEXT NOT NULL
- `created_at` TEXT NOT NULL

### 4. `prescriptions`
- `id` TEXT PRIMARY KEY
- `profile_id` TEXT NOT NULL FOREIGN KEY -> profiles(id) ON DELETE CASCADE
- `user_id` TEXT NOT NULL FOREIGN KEY -> users(id) ON DELETE CASCADE
- `prescription_date` TEXT NOT NULL
- `doctor_name` TEXT
- `clinic_name` TEXT
- `add_power` REAL
- `pd` REAL
- `notes` TEXT
- `image_url` TEXT
- `source` TEXT NOT NULL DEFAULT 'MANUAL'
- `ocr_confidence` REAL NOT NULL DEFAULT 1.0
- `confirmed_by_user` INTEGER NOT NULL DEFAULT 1
- `is_current` INTEGER NOT NULL DEFAULT 1
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

### 5. `prescription_eye_values`
- `id` TEXT PRIMARY KEY
- `prescription_id` TEXT NOT NULL FOREIGN KEY -> prescriptions(id) ON DELETE CASCADE
- `eye` TEXT NOT NULL ('OD', 'OS')
- `sph` REAL
- `cyl` REAL
- `axis` INTEGER
- `sph_status` TEXT NOT NULL DEFAULT 'CONFIRMED'
- `cyl_status` TEXT NOT NULL DEFAULT 'CONFIRMED'
- `axis_status` TEXT NOT NULL DEFAULT 'CONFIRMED'
- `created_at` TEXT NOT NULL

### 6. `medications`
- `id` TEXT PRIMARY KEY
- `profile_id` TEXT NOT NULL FOREIGN KEY -> profiles(id) ON DELETE CASCADE
- `user_id` TEXT NOT NULL FOREIGN KEY -> users(id) ON DELETE CASCADE
- `name` TEXT NOT NULL
- `type` TEXT NOT NULL DEFAULT 'Drop'
- `dosage` TEXT NOT NULL
- `start_date` TEXT NOT NULL
- `end_date` TEXT
- `active` INTEGER NOT NULL DEFAULT 1
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

### 7. `medication_schedules`
- `id` TEXT PRIMARY KEY
- `medication_id` TEXT NOT NULL FOREIGN KEY -> medications(id) ON DELETE CASCADE
- `time` TEXT NOT NULL
- `tone` TEXT NOT NULL DEFAULT 'Soft Chime'
- `vibration_enabled` INTEGER NOT NULL DEFAULT 1
- `enabled` INTEGER NOT NULL DEFAULT 1
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

### 8. `medication_logs`
- `id` TEXT PRIMARY KEY
- `medication_id` TEXT NOT NULL FOREIGN KEY -> medications(id) ON DELETE CASCADE
- `schedule_id` TEXT NOT NULL
- `scheduled_at` TEXT NOT NULL
- `actual_at` TEXT
- `status` TEXT NOT NULL DEFAULT 'TAKEN' ('TAKEN', 'SNOOZED', 'SKIPPED', 'MISSED')
- `created_at` TEXT NOT NULL

### 9. `eye_care_scores`
- `id` TEXT PRIMARY KEY
- `profile_id` TEXT NOT NULL FOREIGN KEY -> profiles(id) ON DELETE CASCADE
- `score` INTEGER NOT NULL
- `prescription_completeness_score` INTEGER NOT NULL
- `prescription_stability_score` INTEGER NOT NULL
- `medication_adherence_score` INTEGER NOT NULL
- `followup_recency_score` INTEGER NOT NULL
- `record_completeness_score` INTEGER NOT NULL
- `care_routine_consistency_score` INTEGER NOT NULL
- `history_quality_score` INTEGER NOT NULL
- `explanation` TEXT NOT NULL
- `algorithm_version` INTEGER NOT NULL DEFAULT 2
- `calculated_at` TEXT NOT NULL

### 10. `subscriptions`
- `id` TEXT PRIMARY KEY
- `user_id` TEXT NOT NULL FOREIGN KEY -> users(id) ON DELETE CASCADE
- `provider` TEXT NOT NULL DEFAULT 'razorpay'
- `provider_customer_id` TEXT
- `provider_order_id` TEXT
- `provider_payment_id` TEXT
- `provider_subscription_id` TEXT
- `plan` TEXT NOT NULL DEFAULT 'free'
- `status` TEXT NOT NULL DEFAULT 'ACTIVE'
- `started_at` TEXT NOT NULL
- `expires_at` TEXT
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL
