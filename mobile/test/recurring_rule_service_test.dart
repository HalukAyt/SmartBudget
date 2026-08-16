import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/models/recurring_models.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/recurring_rule_service.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'service uses exact list, create, delete and realize endpoints',
    () async {
      final storage = MemoryTokenStorage()..token = 'token';
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://api.test',
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' &&
              request.url.path == '/api/recurring-rules') {
            return http.Response('[]', 200);
          }
          if (request.method == 'POST' &&
              request.url.path == '/api/recurring-rules') {
            return http.Response(
              jsonEncode({
                'id': 'rule-created',
                'recordType': 'Income',
                'frequency': 'Monthly',
                'startDate': '2026-08-16',
                'endDate': '2027-01-16',
                'isActive': true,
                'amount': 45000,
                'description': 'Salary',
                'category': null,
                'billType': null,
                'isRealizedThisMonth': false,
                'createdAt': '2026-08-16T12:00:00Z',
              }),
              201,
            );
          }
          if (request.method == 'POST' &&
              request.url.path == '/api/recurring-rules/rule-created/realize') {
            return http.Response(
              jsonEncode({
                'recordType': 'Income',
                'ruleId': 'rule-created',
                'createdRecordId': 'income-99',
                'year': 2026,
                'month': 8,
              }),
              201,
            );
          }
          return http.Response('', 204);
        }),
      );
      final service = RecurringRuleService(apiClient: client);

      await service.getAll();
      await service.create(
        CreateRecurringRuleRequest(
          recordType: RecurringRecordType.income,
          startDate: DateTime(2026, 8, 16),
          durationMonths: 6,
          amount: 45000,
          description: 'Salary',
        ),
      );
      await service.realize(
        'rule-created',
        const RealizeRecurringRuleRequest(year: 2026, month: 8),
      );
      await service.delete('rule-created');

      expect(requests.map((r) => '${r.method} ${r.url.path}'), [
        'GET /api/recurring-rules',
        'POST /api/recurring-rules',
        'POST /api/recurring-rules/rule-created/realize',
        'DELETE /api/recurring-rules/rule-created',
      ]);
      final createPayload =
          jsonDecode(requests[1].body) as Map<String, dynamic>;
      expect(createPayload, isNot(contains('userId')));
    },
  );

  test(
    'fake service supports handlers for isolated view-model tests',
    () async {
      final service = FakeRecurringRuleService(
        items: [sampleRecurringRule(id: 'rule-1')],
      );

      final all = await service.getAll();
      expect(all, hasLength(1));
      expect(service.getAllCalls, 1);

      final result = await service.realize(
        'rule-1',
        const RealizeRecurringRuleRequest(year: 2026, month: 8),
      );
      expect(result.createdRecordId, isNotEmpty);
      expect(service.realizeCalls, 1);
      expect((await service.getAll()).single.isRealizedThisMonth, isTrue);
    },
  );
}
