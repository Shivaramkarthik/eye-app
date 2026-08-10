import 'api_client.dart';

class AiApi {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> extractOCR({String? imageBase64, String? imageUrl}) async {
    final res = await _client.post('/ai/ocr-prescription', data: {
      'image_base64': imageBase64,
      'image_url': imageUrl,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getDoctorQuestions(String profileId, List<String> symptoms) async {
    final res = await _client.post('/ai/doctor-questions', data: {
      'profile_id': profileId,
      'symptoms': symptoms,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getSummary(String profileId) async {
    final res = await _client.post('/ai/summary', data: {
      'profile_id': profileId,
    });
    return res.data;
  }
}
