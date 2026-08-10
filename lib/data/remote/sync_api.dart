import 'api_client.dart';

class SyncApi {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> pushSyncQueue(String deviceId, List<Map<String, dynamic>> operations) async {
    final res = await _client.post('/sync/push', data: {
      'device_id': deviceId,
      'operations': operations,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> pullSyncState() async {
    final res = await _client.get('/sync/pull');
    return res.data;
  }
}
