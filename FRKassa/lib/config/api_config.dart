class ApiConfig {
  // Backend hostname - can be overridden for production
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000',
  );

  static String getCloudCartUrl(String cloudCartId) {
    return '$baseUrl/api/CloudCart/$cloudCartId';
  }

  static const Duration apiTimeout = Duration(seconds: 30);
}
