import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../core/config/backend_config.dart';
import '../models/user_model.dart';
import 'database_service.dart';

/// Handles all authentication operations for Specz.co.
/// 
/// Uses real Google Sign-In for identity, validates on the backend,
/// and stores Specz tokens in FlutterSecureStorage.
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: BackendConfig.googleWebClientId,
  );

  static const String _accessTokenKey = 'specz_access_token';
  static const String _refreshTokenKey = 'specz_refresh_token';
  static const String _userDataKey = 'specz_user_data';

  /// Signs in with Google and authenticates with the Specz backend.
  /// 
  /// Flow:
  /// 1. Google Sign-In SDK → Google account picker
  /// 2. Get Google ID token
  /// 3. Send to backend POST /auth/google
  /// 4. Backend validates with Google's servers
  /// 5. Backend returns Specz access + refresh tokens
  /// 6. Store tokens securely
  /// 
  /// Returns [UserModel] on success, throws on failure.
  Future<UserModel> signInWithGoogle() async {
    // Force clear any cached Google Sign-In state to get a fresh ID token
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    // Step 1: Trigger native Google Sign-In
    final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      throw AuthException('Google Sign-In was cancelled.');
    }

    // Step 2: Get Google ID token
    final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthException('Failed to obtain Google ID token. Please wait 2 minutes for Google Cloud settings to propagate and tap Sign In again.');
    }

    // Step 3: Send ID token to Specz backend for verification
    final response = await http.post(
      Uri.parse('${BackendConfig.baseUrl}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'google_id_token': idToken}),
    ).timeout(
      Duration(milliseconds: BackendConfig.connectTimeoutMs),
      onTimeout: () => throw AuthException('Connection timed out. Please check your internet.'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Step 4: Store Specz tokens securely
      await _secureStorage.write(key: _accessTokenKey, value: data['access_token']);
      await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);

      // Step 5: Build and persist user model
      final user = UserModel(
        id: data['user_id'],
        email: data['email'],
        name: data['name'] ?? googleAccount.displayName ?? 'User',
        avatarUrl: data['avatar_url'] ?? googleAccount.photoUrl,
        plan: data['plan'] ?? 'free',
        status: data['plan'] == 'plus' ? 'active' : 'free',
        createdAt: DateTime.now().toIso8601String(),
      );

      await _secureStorage.write(key: _userDataKey, value: jsonEncode(user.toMap()));
      try {
        await DatabaseService.instance.saveUser(user);
      } catch (_) {}
      return user;
    } else {
      final errorBody = jsonDecode(response.body);
      final detail = errorBody['detail'] ?? 'Authentication failed.';
      throw AuthException(detail);
    }
  }

  /// Refreshes the Specz access token using the stored refresh token.
  /// Returns updated [UserModel] or null if refresh fails.
  Future<UserModel?> refreshToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(Duration(milliseconds: BackendConfig.connectTimeoutMs));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(key: _accessTokenKey, value: data['access_token']);
        await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);

        final user = UserModel(
          id: data['user_id'],
          email: data['email'],
          name: data['name'] ?? 'User',
          avatarUrl: data['avatar_url'],
          plan: data['plan'] ?? 'free',
          status: data['plan'] == 'plus' ? 'active' : 'free',
          createdAt: DateTime.now().toIso8601String(),
        );
        await _secureStorage.write(key: _userDataKey, value: jsonEncode(user.toMap()));
        return user;
      }
    } catch (_) {}

    return null;
  }

  /// Logs out the user — clears tokens and signs out of Google.
  Future<void> logout() async {
    try {
      // Call backend logout if access token exists
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      if (accessToken != null) {
        await http.post(
          Uri.parse('${BackendConfig.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 200));
      }
    } catch (_) {}

    // Clear all stored credentials
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userDataKey);

    // Sign out of Google
    await _googleSignIn.signOut();
  }

  /// Returns the stored access token, or null if not logged in.
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Checks if the user has stored credentials.
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null;
  }

  /// Restores the user session from secure storage.
  /// Returns [UserModel] if session exists, null otherwise.
  Future<UserModel?> restoreSession() async {
    try {
      final userData = await _secureStorage.read(key: _userDataKey);
      if (userData == null) return null;

      final map = jsonDecode(userData) as Map<String, dynamic>;
      return UserModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
