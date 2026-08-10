import 'package:sqflite/sqflite.dart';
import '../../../models/prescription_model.dart';
import '../../../models/prescription_eye_value_model.dart';

class PrescriptionDao {
  final Database db;
  PrescriptionDao(this.db);

  Future<List<PrescriptionModel>> getPrescriptionsForProfile(String profileId, String userId) async {
    final res = await db.query(
      'prescriptions',
      where: 'profile_id = ? AND user_id = ?',
      orderBy: 'prescription_date DESC',
      whereArgs: [profileId, userId],
    );

    List<PrescriptionModel> result = [];
    for (var row in res) {
      final pId = row['id'] as String;
      final eyeValues = await db.query('prescription_eye_values', where: 'prescription_id = ?', whereArgs: [pId]);

      double? rSph, rCyl, lSph, lCyl;
      int? rAxis, lAxis;

      for (var ev in eyeValues) {
        final eye = ev['eye'] as String?;
        if (eye == 'OD') {
          rSph = (ev['sph'] as num?)?.toDouble();
          rCyl = (ev['cyl'] as num?)?.toDouble();
          rAxis = (ev['axis'] as num?)?.toInt();
        } else if (eye == 'OS') {
          lSph = (ev['sph'] as num?)?.toDouble();
          lCyl = (ev['cyl'] as num?)?.toDouble();
          lAxis = (ev['axis'] as num?)?.toInt();
        }
      }

      Map<String, dynamic> mutableMap = Map<String, dynamic>.from(row);
      mutableMap['profileId'] = row['profile_id'];
      mutableMap['userId'] = row['user_id'];
      mutableMap['prescriptionDate'] = row['prescription_date'];
      mutableMap['doctorName'] = row['doctor_name'];
      mutableMap['clinicName'] = row['clinic_name'];
      mutableMap['addPower'] = row['add_power'];
      mutableMap['imageUrl'] = row['image_url'];
      mutableMap['isCurrent'] = row['is_current'];
      mutableMap['createdAt'] = row['created_at'];

      mutableMap['rightSph'] = rSph;
      mutableMap['rightCyl'] = rCyl;
      mutableMap['rightAxis'] = rAxis;
      mutableMap['leftSph'] = lSph;
      mutableMap['leftCyl'] = lCyl;
      mutableMap['leftAxis'] = lAxis;

      result.add(PrescriptionModel.fromMap(mutableMap));
    }
    return result;
  }

  Future<void> insertPrescription(PrescriptionModel prescription, {List<PrescriptionEyeValueModel>? eyeValues}) async {
    await db.transaction((txn) async {
      if (prescription.isCurrent) {
        await txn.update(
          'prescriptions',
          {'is_current': 0},
          where: 'profile_id = ? AND user_id = ?',
          whereArgs: [prescription.profileId, prescription.userId],
        );
      }

      await txn.insert('prescriptions', {
        'id': prescription.id,
        'profile_id': prescription.profileId,
        'user_id': prescription.userId,
        'prescription_date': prescription.prescriptionDate,
        'doctor_name': prescription.doctorName,
        'clinic_name': prescription.clinicName,
        'add_power': prescription.addPower,
        'pd': prescription.pd,
        'notes': prescription.notes,
        'image_url': prescription.imageUrl,
        'source': 'MANUAL',
        'ocr_confidence': 1.0,
        'confirmed_by_user': 1,
        'is_current': prescription.isCurrent ? 1 : 0,
        'created_at': prescription.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Delete existing eye values for this prescription
      await txn.delete('prescription_eye_values', where: 'prescription_id = ?', whereArgs: [prescription.id]);

      // Insert OD (Right Eye)
      await txn.insert('prescription_eye_values', {
        'id': '${prescription.id}_OD',
        'prescription_id': prescription.id,
        'eye': 'OD',
        'sph': prescription.rightSph,
        'cyl': prescription.rightCyl,
        'axis': prescription.rightAxis,
        'sph_status': prescription.rightSph == null ? 'MISSING' : 'CONFIRMED',
        'cyl_status': prescription.rightCyl == null ? 'MISSING' : 'CONFIRMED',
        'axis_status': prescription.rightAxis == null ? 'MISSING' : 'CONFIRMED',
        'created_at': prescription.createdAt,
      });

      // Insert OS (Left Eye)
      await txn.insert('prescription_eye_values', {
        'id': '${prescription.id}_OS',
        'prescription_id': prescription.id,
        'eye': 'OS',
        'sph': prescription.leftSph,
        'cyl': prescription.leftCyl,
        'axis': prescription.leftAxis,
        'sph_status': prescription.leftSph == null ? 'MISSING' : 'CONFIRMED',
        'cyl_status': prescription.leftCyl == null ? 'MISSING' : 'CONFIRMED',
        'axis_status': prescription.leftAxis == null ? 'MISSING' : 'CONFIRMED',
        'created_at': prescription.createdAt,
      });
    });
  }
}
