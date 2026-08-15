enum Environment { development, staging, production }

class BackendConfig {
  static Environment currentEnv = Environment.production;

  static String get baseUrl {
    switch (currentEnv) {
      case Environment.development:
        return 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost
      case Environment.staging:
        return 'https://staging-api.specz.co/api/v1';
      case Environment.production:
        return 'https://api.specz.co/api/v1';
    }
  }

  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 15000;

  /// Google OAuth Web Client ID (used as serverClientId for ID token exchange)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '27928063402-hob0r74jfqp29jg6ljp1o1dj1d73n5db.apps.googleusercontent.com',
  );
}

