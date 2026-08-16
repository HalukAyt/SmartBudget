import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../storage/secure_storage_service.dart';
import 'api_client.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthService extends ChangeNotifier {
  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage {
    _apiClient.onUnauthorized = handleUnauthorized;
  }

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.checking;
  String? _email;
  String? _sessionMessage;

  AuthStatus get status => _status;
  String? get email => _email;
  String? get sessionMessage => _sessionMessage;

  Future<bool> hasToken() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> initialize() async {
    final token = await _tokenStorage.readToken();
    _email = await _tokenStorage.readEmail();
    _status = token != null && token.isNotEmpty
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      '/api/auth/register',
      body: RegisterRequest(email: email.trim(), password: password).toJson(),
      requiresAuth: false,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _apiClient.post(
      '/api/auth/login',
      body: LoginRequest(email: email.trim(), password: password).toJson(),
      requiresAuth: false,
    );

    if (result is! Map<String, Object?>) {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }

    final auth = AuthResponse.fromJson(result);
    await _tokenStorage.saveToken(auth.accessToken);
    await _tokenStorage.saveEmail(auth.email);
    _email = auth.email;
    _sessionMessage = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSession();
    _sessionMessage = null;
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    await _clearSession();
    _sessionMessage = 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _tokenStorage.deleteToken();
    await _tokenStorage.deleteEmail();
    _email = null;
    _status = AuthStatus.unauthenticated;
  }
}
