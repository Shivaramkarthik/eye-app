import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class DatabaseMigrationManager {
  static Future<void> createV2Schema(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        phone TEXT,
        first_name TEXT,
        last_name TEXT,
        display_name TEXT,
        plan TEXT NOT NULL DEFAULT 'free',
        account_status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // profiles
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        dob TEXT NOT NULL,
        gender TEXT NOT NULL,
        relationship TEXT NOT NULL DEFAULT 'Self',
        profile_type TEXT NOT NULL DEFAULT 'Adult',
        prescription_type TEXT,
        blurred_vision_type TEXT,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // profile_symptoms
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_symptoms (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        symptom TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // prescriptions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prescriptions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        prescription_date TEXT NOT NULL,
        doctor_name TEXT,
        clinic_name TEXT,
        add_power REAL,
        pd REAL,
        notes TEXT,
        image_url TEXT,
        source TEXT NOT NULL DEFAULT 'MANUAL',
        ocr_confidence REAL NOT NULL DEFAULT 1.0,
        confirmed_by_user INTEGER NOT NULL DEFAULT 1,
        is_current INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // prescription_eye_values
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prescription_eye_values (
        id TEXT PRIMARY KEY,
        prescription_id TEXT NOT NULL,
        eye TEXT NOT NULL,
        sph REAL,
        cyl REAL,
        axis INTEGER,
        sph_status TEXT NOT NULL DEFAULT 'CONFIRMED',
        cyl_status TEXT NOT NULL DEFAULT 'CONFIRMED',
        axis_status TEXT NOT NULL DEFAULT 'CONFIRMED',
        created_at TEXT NOT NULL,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
      )
    ''');

    // medications
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medications (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'Drop',
        dosage TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // medication_schedules
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medication_schedules (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        time TEXT NOT NULL,
        tone TEXT NOT NULL DEFAULT 'Soft Chime',
        vibration_enabled INTEGER NOT NULL DEFAULT 1,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // medication_logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medication_logs (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        schedule_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        actual_at TEXT,
        status TEXT NOT NULL DEFAULT 'TAKEN',
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // eye_care_scores
    await db.execute('''
      CREATE TABLE IF NOT EXISTS eye_care_scores (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        score INTEGER NOT NULL,
        prescription_completeness_score INTEGER NOT NULL DEFAULT 20,
        prescription_stability_score INTEGER NOT NULL DEFAULT 15,
        medication_adherence_score INTEGER NOT NULL DEFAULT 20,
        followup_recency_score INTEGER NOT NULL DEFAULT 10,
        record_completeness_score INTEGER NOT NULL DEFAULT 10,
        care_routine_consistency_score INTEGER NOT NULL DEFAULT 10,
        history_quality_score INTEGER NOT NULL DEFAULT 15,
        explanation TEXT NOT NULL,
        algorithm_version INTEGER NOT NULL DEFAULT 2,
        calculated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // ai_summaries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_summaries (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        summary_text TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        model_version TEXT NOT NULL DEFAULT 'gemini-1.5-flash',
        prompt_version TEXT NOT NULL DEFAULT 'v2.0',
        generated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // doctor_questions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctor_questions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        question_text TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        generated_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // reports
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reports (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        report_date TEXT NOT NULL,
        title TEXT NOT NULL,
        clinic_name TEXT,
        file_path TEXT,
        notes TEXT,
        follow_up_date TEXT,
        score_snapshot INTEGER NOT NULL DEFAULT 85,
        score_explanation_snapshot TEXT,
        ai_summary_snapshot TEXT,
        doctor_questions_snapshot TEXT,
        report_version INTEGER NOT NULL DEFAULT 2,
        language TEXT NOT NULL DEFAULT 'en',
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // subscriptions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        provider TEXT NOT NULL DEFAULT 'razorpay',
        provider_customer_id TEXT,
        provider_order_id TEXT,
        provider_payment_id TEXT,
        provider_subscription_id TEXT,
        plan TEXT NOT NULL DEFAULT 'free',
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        started_at TEXT NOT NULL,
        expires_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> migrateFromV1ToV2(Database db) async {
    // Transactional safety during migration
    await db.transaction((txn) async {
      // 1. Migrate profile symptoms from JSON text to profile_symptoms table
      try {
        final profiles = await txn.rawQuery('SELECT id, symptoms FROM profiles WHERE symptoms IS NOT NULL');
        for (var p in profiles) {
          final pid = p['id'] as String;
          final symStr = p['symptoms'] as String?;
          if (symStr != null && symStr.isNotEmpty) {
            try {
              List<dynamic> list = jsonDecode(symStr);
              for (var sym in list) {
                if (sym is String && sym.isNotEmpty) {
                  await txn.insert('profile_symptoms', {
                    'id': '${pid}_${sym.hashCode}',
                    'profile_id': pid,
                    'symptom': sym,
                    'created_at': DateTime.now().toIso8601String(),
                  }, conflictAlgorithm: ConflictAlgorithm.ignore);
                }
              }
            } catch (_) {}
          }
        }
      } catch (_) {}

      // 2. Migrate flat prescription eye values to prescription_eye_values table
      try {
        final prescriptions = await txn.rawQuery('SELECT id, rightSph, rightCyl, rightAxis, leftSph, leftCyl, leftAxis, createdAt FROM prescriptions');
        for (var pr in prescriptions) {
          final id = pr['id'] as String;
          final createdAt = (pr['createdAt'] as String?) ?? DateTime.now().toIso8601String();

          // Right eye (OD)
          double? rSph = (pr['rightSph'] as num?)?.toDouble();
          double? rCyl = (pr['rightCyl'] as num?)?.toDouble();
          int? rAxis = (pr['rightAxis'] as num?)?.toInt();

          await txn.insert('prescription_eye_values', {
            'id': '${id}_OD',
            'prescription_id': id,
            'eye': 'OD',
            'sph': rSph,
            'cyl': rCyl,
            'axis': rAxis,
            'sph_status': rSph == null ? 'MISSING' : 'CONFIRMED',
            'cyl_status': rCyl == null ? 'MISSING' : 'CONFIRMED',
            'axis_status': rAxis == null ? 'MISSING' : 'CONFIRMED',
            'created_at': createdAt,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);

          // Left eye (OS)
          double? lSph = (pr['leftSph'] as num?)?.toDouble();
          double? lCyl = (pr['leftCyl'] as num?)?.toDouble();
          int? lAxis = (pr['leftAxis'] as num?)?.toInt();

          await txn.insert('prescription_eye_values', {
            'id': '${id}_OS',
            'prescription_id': id,
            'eye': 'OS',
            'sph': lSph,
            'cyl': lCyl,
            'axis': lAxis,
            'sph_status': lSph == null ? 'MISSING' : 'CONFIRMED',
            'cyl_status': lCyl == null ? 'MISSING' : 'CONFIRMED',
            'axis_status': lAxis == null ? 'MISSING' : 'CONFIRMED',
            'created_at': createdAt,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (_) {}

      // 3. Migrate medicine times JSON and completedLogs JSON to normalized tables
      try {
        final medicines = await txn.rawQuery('SELECT id, times, completedLogs, tone, vibrationEnabled, createdAt FROM medicines');
        for (var med in medicines) {
          final medId = med['id'] as String;
          final tone = (med['tone'] as String?) ?? 'Soft Chime';
          final vib = (med['vibrationEnabled'] == 1 || med['vibrationEnabled'] == true) ? 1 : 0;
          final createdAt = (med['createdAt'] as String?) ?? DateTime.now().toIso8601String();

          final timesStr = med['times'] as String?;
          if (timesStr != null) {
            try {
              List<dynamic> timesList = jsonDecode(timesStr);
              for (int i = 0; i < timesList.length; i++) {
                final t = timesList[i].toString();
                final schedId = '${medId}_sched_$i';
                await txn.insert('medication_schedules', {
                  'id': schedId,
                  'medication_id': medId,
                  'time': t,
                  'tone': tone,
                  'vibration_enabled': vib,
                  'enabled': 1,
                  'created_at': createdAt,
                  'updated_at': createdAt,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
            } catch (_) {}
          }

          final logsStr = med['completedLogs'] as String?;
          if (logsStr != null) {
            try {
              List<dynamic> logsList = jsonDecode(logsStr);
              for (var l in logsList) {
                final logKey = l.toString(); // e.g. "2026-08-09_08:00 AM"
                await txn.insert('medication_logs', {
                  'id': '${medId}_log_${logKey.hashCode}',
                  'medication_id': medId,
                  'schedule_id': '${medId}_sched_0',
                  'scheduled_at': logKey,
                  'actual_at': logKey,
                  'status': 'TAKEN',
                  'created_at': createdAt,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    });
  }
}
