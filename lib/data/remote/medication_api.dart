import 'api_client.dart';
import '../../models/medicine_model.dart';

class MedicationApi {
  final ApiClient _client = ApiClient.instance;

  Future<List<MedicineModel>> getMedications(String profileId) async {
    final res = await _client.get('/profiles/$profileId/medications');
    final list = res.data as List;
    return list.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<void> createMedication(String profileId, MedicineModel m) async {
    List<Map<String, dynamic>> schedules = m.times.map((t) => {'time': t, 'tone': m.tone, 'vibration_enabled': m.vibrationEnabled ? 1 : 0}).toList();

    await _client.post('/profiles/$profileId/medications', data: {
      'name': m.name,
      'type': m.type,
      'dosage': m.dosage,
      'start_date': m.startDate,
      'end_date': m.endDate,
      'active': m.active ? 1 : 0,
      'schedules': schedules,
    });
  }

  Future<void> deleteMedication(String id) async {
    await _client.delete('/medications/$id');
  }
}
