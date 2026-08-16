import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/services/ai_categorization_service.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'categorize uses the longer AI timeout instead of the client default',
    () async {
      // The client's own default timeout is intentionally tiny; only the
      // AI timeout override can survive the slow response below.
      final service = AiCategorizationService(
        apiClient: ApiClient(
          baseUrl: 'https://api.example.test',
          tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
          timeout: const Duration(milliseconds: 30),
          httpClient: MockClient((request) async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
            return http.Response.bytes(
              utf8.encode(
                '{"success":true,"categoryId":"category-market","category":"Market","confidence":0.9,"requiresManualSelection":false,"message":"Öneri oluşturuldu."}',
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );

      final result = await service.categorize('Market alışverişi');

      expect(result.category, 'Market');
    },
  );
}
