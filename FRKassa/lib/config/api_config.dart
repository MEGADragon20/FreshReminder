class ApiConfig {
  /// Backend hostname - can be overridden for production
  /// Usage: flutter run --dart-define=API_URL=https://yourdomain.com
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// Generate ShoppingTrip endpoint (creates QR token)
  /// POST /api/import/generate
  /// Returns: { token, qr_url, expires_at }
  static String get generateTripUrl => '$baseUrl/api/import/generate';

  /// Import/retrieve ShoppingTrip endpoint (for FreshReminder customer app)
  /// GET /api/import/{token}
  static String getImportUrl(String token) => '$baseUrl/api/import/$token';

  static const Duration apiTimeout = Duration(seconds: 30);
}
