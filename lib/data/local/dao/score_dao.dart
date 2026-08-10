import 'package:sqflite/sqflite.dart';
import '../../../models/eye_care_score_model.dart';

class ScoreDao {
  final Database db;
  ScoreDao(this.db);

  Future<void> saveEyeCareScore(EyeCareScoreModel scoreModel, String userId) async {
    // Verify ownership before saving
    final check = await db.query('profiles', where: 'id = ? AND user_id = ?', whereArgs: [scoreModel.profileId, userId]);
    if (check.isEmpty) return;
    await db.insert('eye_care_scores', scoreModel.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<EyeCareScoreModel?> getLatestScore(String profileId, String userId) async {
    final res = await db.rawQuery('''
      SELECT ecs.*
      FROM eye_care_scores ecs
      JOIN profiles p ON ecs.profile_id = p.id
      WHERE ecs.profile_id = ? AND p.user_id = ?
      ORDER BY ecs.calculated_at DESC
      LIMIT 1
    ''', [profileId, userId]);

    if (res.isNotEmpty) {
      return EyeCareScoreModel.fromMap(res.first);
    }
    return null;
  }
}
