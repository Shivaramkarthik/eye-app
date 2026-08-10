import 'api_client.dart';
import '../../models/user_model.dart';

class AuthApi {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.post('/auth/login', data: {'email': email, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> register(String email, String password, {String? name, String? phone}) async {
    final res = await _client.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
    });
    return res.data;
  }

  Future<UserModel?> getMe() async {
    final res = await _client.get('/auth/me');
    return UserModel.fromMap(res.data);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {}
    await _client.secureStorage.delete(key: 'jwt_access_token');
    await _client.secureStorage.delete(key: 'jwt_refresh_token');
  }

  Future<void> deleteAccount() async {
    await _client.delete('/auth/account');
    await _client.secureStorage.delete(key: 'jwt_access_token');
    await _client.secureStorage.delete(key: 'jwt_refresh_token');
  }
}
