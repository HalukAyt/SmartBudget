abstract final class ApiConfig {
  /// Android emulator default. Override for iOS simulator or real devices with:
  /// --dart-define=API_BASE_URL=http://localhost:5259
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5259',
  );

  static const Duration timeout = Duration(seconds: 15);

  /// Used only for AI endpoints (gider kategorileme, aylık analiz). Real
  /// OpenAI Responses API calls routinely take 20-30s; the backend's own
  /// HTTP client timeout for these calls is 60s, so the mobile client must
  /// wait a little longer than that to actually see the backend's response
  /// instead of giving up first.
  static const Duration aiTimeout = Duration(seconds: 65);
}
