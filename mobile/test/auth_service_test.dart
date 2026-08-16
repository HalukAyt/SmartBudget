import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smartbudget_mobile/services/auth_service.dart';

import 'helpers/fakes.dart';

void main() {
  test('register sends only backend email and password fields', () async {
    final storage = MemoryTokenStorage();
    Map<String, Object?>? requestBody;
    final service = createAuthService(
      storage: storage,
      handler: (request) async {
        requestBody = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response('', 201);
      },
    );
    await service.initialize();

    await service.register(email: ' user@example.com ', password: '12345678');

    expect(requestBody, {'email': 'user@example.com', 'password': '12345678'});
    expect(requestBody, isNot(contains('userId')));
    expect(requestBody, isNot(contains('passwordConfirmation')));
    expect(service.status, AuthStatus.unauthenticated);
  });

  test('successful login stores access token and email', () async {
    final storage = MemoryTokenStorage();
    final service = createAuthService(
      storage: storage,
      handler: (_) async => http.Response(
        '{"accessToken":"jwt-token","userId":"d2719e6d-a20b-4a16-a3be-1036c5c3500f","email":"user@example.com"}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    await service.login(email: ' user@example.com ', password: 'password');

    expect(storage.token, 'jwt-token');
    expect(storage.email, 'user@example.com');
    expect(service.status, AuthStatus.authenticated);
  });

  test('logout deletes token and authenticated email', () async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'user@example.com';
    final service = createAuthService(
      storage: storage,
      handler: (_) async => http.Response('', 500),
    );
    await service.initialize();

    await service.logout();

    expect(storage.token, isNull);
    expect(storage.email, isNull);
    expect(service.status, AuthStatus.unauthenticated);
  });
}
