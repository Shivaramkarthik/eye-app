import 'api_client.dart';
import '../../models/prescription_model.dart';

class PrescriptionApi {
  final ApiClient _client = ApiClient.instance;

  Future<List<PrescriptionModel>> getPrescriptions(String profileId) async {
    final res = await _client.get('/profiles/$profileId/prescriptions');
    final list = res.data as List;
    return list.map((p) => PrescriptionModel.fromMap(p)).toList();
  }

  Future<void> createPrescription(String profileId, PrescriptionModel p) async {
    List<Map<String, dynamic>> eyeValues = [];
    if (p.rightSph != null || p.rightCyl != null) {
      eyeValues.add({
        'eye': 'OD',
        'sph': p.rightSph,
        'cyl': p.rightCyl,
        'axis': p.rightAxis,
        'sph_status': p.rightSph == null ? 'MISSING' : 'CONFIRMED',
        'cyl_status': p.rightCyl == null ? 'MISSING' : 'CONFIRMED',
        'axis_status': p.rightAxis == null ? 'MISSING' : 'CONFIRMED',
      });
    }
    if (p.leftSph != null || p.leftCyl != null) {
      eyeValues.add({
        'eye': 'OS',
        'sph': p.leftSph,
        'cyl': p.leftCyl,
        'axis': p.leftAxis,
        'sph_status': p.leftSph == null ? 'MISSING' : 'CONFIRMED',
        'cyl_status': p.leftCyl == null ? 'MISSING' : 'CONFIRMED',
        'axis_status': p.leftAxis == null ? 'MISSING' : 'CONFIRMED',
      });
    }

    await _client.post('/profiles/$profileId/prescriptions', data: {
      'prescription_date': p.prescriptionDate,
      'doctor_name': p.doctorName,
      'clinic_name': p.clinicName,
      'add_power': p.addPower,
      'pd': p.pd,
      'notes': p.notes,
      'image_url': p.imageUrl,
      'source': p.source,
      'ocr_confidence': p.ocrConfidence,
      'confirmed_by_user': p.confirmedByUser ? 1 : 0,
      'is_current': p.isCurrent ? 1 : 0,
      'eye_values': eyeValues,
    });
  }

  Future<void> deletePrescription(String id) async {
    await _client.delete('/prescriptions/$id');
  }
}
