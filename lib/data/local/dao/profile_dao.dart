import 'package:sqflite/sqflite.dart';
import '../../../models/profile_model.dart';

class ProfileDao {
  final Database db;
  ProfileDao(this.db);

  Future<List<ProfileModel>> getProfilesForUser(String userId) async {
    final res = await db.rawQuery('''
      SELECT p.*, GROUP_CONCAT(ps.symptom, '|||') as symptoms_concat
      FROM profiles p
      LEFT JOIN profile_symptoms ps ON p.id = ps.profile_id
      WHERE p.user_id = ? AND p.archived = 0 AND (p.deleted_at IS NULL)
      GROUP BY p.id
      ORDER BY p.created_at ASC
    ''', [userId]);

    return res.map((map) {
      final symptomsStr = map['symptoms_concat'] as String?;
      List<String> symptomsList = symptomsStr != null ? symptomsStr.split('|||').where((s) => s.isNotEmpty).toList() : [];
      
      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(map);
      mutableMap['symptoms'] = symptomsList;
      mutableMap['userId'] = map['user_id'];
      mutableMap['isArchived'] = map['archived'];
      return ProfileModel.fromMap(mutableMap);
    }).toList();
  }

  Future<int> getActiveProfileCount(String userId) async {
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM profiles WHERE user_id = ? AND archived = 0 AND (deleted_at IS NULL)',
      [userId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> insertProfile(ProfileModel profile) async {
    await db.transaction((txn) async {
      await txn.insert('profiles', {
        'id': profile.id,
        'user_id': profile.userId,
        'name': profile.name,
        'dob': profile.dob,
        'gender': profile.gender,
        'relationship': profile.relationship,
        'profile_type': profile.type,
        'prescription_type': profile.prescriptionType,
        'blurred_vision_type': profile.blurredVisionType,
        'archived': profile.isArchived ? 1 : 0,
        'created_at': profile.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert symptoms into normalized table profile_symptoms
      await txn.delete('profile_symptoms', where: 'profile_id = ?', whereArgs: [profile.id]);
      for (var sym in profile.symptoms) {
        await txn.insert('profile_symptoms', {
          'id': '${profile.id}_${sym.hashCode}',
          'profile_id': profile.id,
          'symptom': sym,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await insertProfile(profile);
  }

  Future<void> deleteProfileCascade(String profileId, String userId) async {
    await db.transaction((txn) async {
      // Enforce ownership check
      final check = await txn.query('profiles', where: 'id = ? AND user_id = ?', whereArgs: [profileId, userId]);
      if (check.isEmpty) return;

      await txn.delete('profile_symptoms', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('prescription_eye_values', where: 'prescription_id IN (SELECT id FROM prescriptions WHERE profile_id = ?)', whereArgs: [profileId]);
      await txn.delete('prescriptions', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('medication_logs', where: 'medication_id IN (SELECT id FROM medications WHERE profile_id = ?)', whereArgs: [profileId]);
      await txn.delete('medication_schedules', where: 'medication_id IN (SELECT id FROM medications WHERE profile_id = ?)', whereArgs: [profileId]);
      await txn.delete('medications', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('eye_care_scores', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('ai_summaries', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('doctor_questions', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('reports', where: 'profile_id = ?', whereArgs: [profileId]);
      await txn.delete('profiles', where: 'id = ? AND user_id = ?', whereArgs: [profileId, userId]);
    });
  }
}
