import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/backend_config.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  late final Dio dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: BackendConfig.baseUrl,
        connectTimeout: Duration(milliseconds: BackendConfig.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: BackendConfig.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth Token Interceptor & Refresh logic
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: 'jwt_access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Attempt Refresh Token Rotation
            final refreshToken = await secureStorage.read(key: 'jwt_refresh_token');
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: BackendConfig.baseUrl));
                final response = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (response.statusCode == 200) {
                  final newAccessToken = response.data['access_token'];
                  final newRefreshToken = response.data['refresh_token'];

                  await secureStorage.write(key: 'jwt_access_token', value: newAccessToken);
                  await secureStorage.write(key: 'jwt_refresh_token', value: newRefreshToken);

                  // Retry original request
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final clonedResponse = await dio.fetch(error.requestOptions);
                  return handler.resolve(clonedResponse);
                }
              } catch (_) {
                await secureStorage.delete(key: 'jwt_access_token');
                await secureStorage.delete(key: 'jwt_refresh_token');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
