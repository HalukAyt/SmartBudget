import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/config/api_config.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/auth_service.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'ApiConfig keeps the global timeout at 15s and defines a longer AI timeout',
    () {
      expect(ApiConfig.timeout, const Duration(seconds: 15));
      expect(ApiConfig.aiTimeout, const Duration(seconds: 65));
    },
  );

  test(
    'a per-request timeout override is honored instead of the client default',
    () async {
      // The client's own default is intentionally tiny; a slow response would
      // trip it unless the per-request override actually takes effect.
      final client = ApiClient(
        baseUrl: 'https://api.example.test',
        tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
        timeout: const Duration(milliseconds: 30),
        httpClient: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          return http.Response('{}', 200);
        }),
      );

      final result = await client.get(
        '/api/ai/categorize-expense',
        timeout: const Duration(milliseconds: 300),
      );

      expect(result, isA<Map<String, Object?>>());
    },
  );

  test(
    'omitting a per-request timeout falls back to the client default',
    () async {
      final client = ApiClient(
        baseUrl: 'https://api.example.test',
        tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
        timeout: const Duration(milliseconds: 30),
        httpClient: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        client.get('/api/categories'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.timeout,
          ),
        ),
      );
    },
  );

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
