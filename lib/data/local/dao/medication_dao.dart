import 'package:sqflite/sqflite.dart';
import '../../../models/medicine_model.dart';
import '../../../models/medication_schedule_model.dart';
import '../../../models/medication_log_model.dart';

class MedicationDao {
  final Database db;
  MedicationDao(this.db);

  Future<List<MedicineModel>> getMedicinesForProfile(String profileId, String userId) async {
    final res = await db.query(
      'medications',
      where: 'profile_id = ? AND user_id = ?',
      whereArgs: [profileId, userId],
    );

    List<MedicineModel> list = [];
    for (var m in res) {
      final medId = m['id'] as String;
      final schedules = await db.query('medication_schedules', where: 'medication_id = ? AND enabled = 1', whereArgs: [medId]);
      List<String> times = schedules.map((s) => s['time'] as String).toList();

      final tone = schedules.isNotEmpty ? (schedules.first['tone'] as String) : 'Soft Chime';
      final vib = schedules.isNotEmpty ? ((schedules.first['vibration_enabled'] == 1) || (schedules.first['vibration_enabled'] == true)) : true;

      final logs = await db.query('medication_logs', where: 'medication_id = ? AND status = ?', whereArgs: [medId, 'TAKEN']);
      List<String> completedLogs = logs.map((l) => l['scheduled_at'] as String).toList();

      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(m);
      mutableMap['profileId'] = m['profile_id'];
      mutableMap['userId'] = m['user_id'];
      mutableMap['startDate'] = m['start_date'];
      mutableMap['endDate'] = m['end_date'];
      mutableMap['times'] = times;
      mutableMap['tone'] = tone;
      mutableMap['vibrationEnabled'] = vib;
      mutableMap['active'] = m['active'];
      mutableMap['completedLogs'] = completedLogs;
      mutableMap['createdAt'] = m['created_at'];

      list.add(MedicineModel.fromMap(mutableMap));
    }
    return list;
  }

  Future<void> insertMedicine(MedicineModel med) async {
    await db.transaction((txn) async {
      await txn.insert('medications', {
        'id': med.id,
        'profile_id': med.profileId,
        'user_id': med.userId,
        'name': med.name,
        'type': med.type,
        'dosage': med.dosage,
        'start_date': med.startDate,
        'end_date': med.endDate,
        'active': med.active ? 1 : 0,
        'created_at': med.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Re-insert normalized schedules
      await txn.delete('medication_schedules', where: 'medication_id = ?', whereArgs: [med.id]);
      for (int i = 0; i < med.times.length; i++) {
        final t = med.times[i];
        await txn.insert('medication_schedules', {
          'id': '${med.id}_sched_$i',
          'medication_id': med.id,
          'time': t,
          'tone': med.tone,
          'vibration_enabled': med.vibrationEnabled ? 1 : 0,
          'enabled': 1,
          'created_at': med.createdAt,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> logMedicationDose({
    required String medicationId,
    required String scheduleId,
    required String scheduledAt,
    required String status, // 'TAKEN', 'SNOOZED', 'SKIPPED', 'MISSED'
  }) async {
    final logId = '${medicationId}_log_${scheduledAt.hashCode}';
    await db.insert('medication_logs', {
      'id': logId,
      'medication_id': medicationId,
      'schedule_id': scheduleId,
      'scheduled_at': scheduledAt,
      'actual_at': DateTime.now().toIso8601String(),
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMedicine(String id, String userId) async {
    await db.transaction((txn) async {
      final check = await txn.query('medications', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
      if (check.isEmpty) return;
      await txn.delete('medication_logs', where: 'medication_id = ?', whereArgs: [id]);
      await txn.delete('medication_schedules', where: 'medication_id = ?', whereArgs: [id]);
      await txn.delete('medications', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
    });
  }

  Future<double> calculateAdherenceRate(String profileId) async {
    final logs = await db.rawQuery('''
      SELECT status, COUNT(*) as cnt
      FROM medication_logs ml
      JOIN medications m ON ml.medication_id = m.id
      WHERE m.profile_id = ?
      GROUP BY status
    ''', [profileId]);

    int taken = 0;
    int total = 0;

    for (var row in logs) {
      final status = row['status'] as String;
      final cnt = (row['cnt'] as num).toInt();
      total += cnt;
      if (status == 'TAKEN') {
        taken += cnt;
      }
    }

    if (total == 0) return 1.0; // 100% baseline when no past logs exist
    return (taken / total).clamp(0.0, 1.0);
  }
}
