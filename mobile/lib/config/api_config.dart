abstract final class ApiConfig {
  /// Android emulator default. Override for iOS simulator or real devices with:
  /// --dart-define=API_BASE_URL=http://localhost:5259
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5259',
  );

  static const Duration timeout = Duration(seconds: 15);
}
