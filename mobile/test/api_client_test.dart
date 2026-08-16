import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/auth_service.dart';

import 'helpers/fakes.dart';

void main() {
  test('protected request adds bearer authorization header', () async {
    final storage = MemoryTokenStorage()..token = 'jwt-token';
    String? authorizationHeader;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      tokenStorage: storage,
      httpClient: MockClient((request) async {
        authorizationHeader = request.headers['authorization'];
        return http.Response('{}', 200);
      }),
    );

    await client.get('/api/categories');

    expect(authorizationHeader, 'Bearer jwt-token');
  });

  test('protected 401 clears session through central handler', () async {
    final storage = MemoryTokenStorage()
      ..token = 'expired-token'
      ..email = 'user@example.com';
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      tokenStorage: storage,
      httpClient: MockClient((_) async => http.Response('', 401)),
    );
    final authService = AuthService(apiClient: client, tokenStorage: storage);
    await authService.initialize();

    await expectLater(
      client.get('/api/categories'),
      throwsA(isA<ApiException>()),
    );

    expect(storage.token, isNull);
    expect(authService.status, AuthStatus.unauthenticated);
    expect(
      authService.sessionMessage,
      'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
    );
  });
}
