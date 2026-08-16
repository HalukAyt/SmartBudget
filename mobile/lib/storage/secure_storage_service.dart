import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();
  Future<void> saveEmail(String email);
  Future<String?> readEmail();
  Future<void> deleteEmail();
}

abstract interface class TutorialStorage {
  Future<bool> hasSeenTutorial(String userEmail);
  Future<void> markTutorialSeen(String userEmail);
}

class SecureStorageService implements TokenStorage, TutorialStorage {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'smartbudget_access_token';
  static const _emailKey = 'smartbudget_authenticated_email';
  static const _tutorialSeenPrefix = 'tutorial_seen_v1_';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  @override
  Future<void> saveEmail(String email) =>
      _storage.write(key: _emailKey, value: email);

  @override
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  @override
  Future<void> deleteEmail() => _storage.delete(key: _emailKey);

  @override
  Future<bool> hasSeenTutorial(String userEmail) async =>
      await _storage.read(key: _tutorialKey(userEmail)) == 'true';

  @override
  Future<void> markTutorialSeen(String userEmail) =>
      _storage.write(key: _tutorialKey(userEmail), value: 'true');

  String _tutorialKey(String userEmail) =>
      '$_tutorialSeenPrefix${userEmail.trim().toLowerCase()}';
}
