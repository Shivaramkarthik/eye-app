import 'package:sqflite/sqflite.dart';
import '../../../models/report_model.dart';

class ReportDao {
  final Database db;
  ReportDao(this.db);

  Future<List<ReportModel>> getReportsForProfile(String profileId, String userId) async {
    final res = await db.query(
      'reports',
      where: 'profile_id = ? AND user_id = ?',
      orderBy: 'report_date DESC',
      whereArgs: [profileId, userId],
    );
    return res.map((r) {
      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(r);
      mutableMap['profileId'] = r['profile_id'];
      mutableMap['userId'] = r['user_id'];
      mutableMap['reportDate'] = r['report_date'];
      mutableMap['clinicName'] = r['clinic_name'];
      mutableMap['filePath'] = r['file_path'];
      mutableMap['followUpDate'] = r['follow_up_date'];
      mutableMap['createdAt'] = r['created_at'];
      return ReportModel.fromMap(mutableMap);
    }).toList();
  }

  Future<void> insertReport(ReportModel report) async {
    await db.insert('reports', {
      'id': report.id,
      'profile_id': report.profileId,
      'user_id': report.userId,
      'report_date': report.reportDate,
      'title': report.title,
      'clinic_name': report.clinicName,
      'file_path': report.filePath,
      'notes': report.notes,
      'follow_up_date': report.followUpDate,
      'report_version': 2,
      'language': 'en',
      'created_at': report.createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
