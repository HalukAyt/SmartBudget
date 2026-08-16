import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/dashboard_service.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'default dashboard request uses monthly endpoint without query',
    () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return http.Response(jsonEncode(_dashboardJson()), 200);
      });

      final dashboard = await service.getMonthly();

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/dashboard/monthly');
      expect(captured.url.query, isEmpty);
      expect(dashboard.year, 2026);
      expect(dashboard.budgetUsages.single.alertStatus.name, 'warning');
    },
  );

  test('selected dashboard period is sent as year and month query', () async {
    late http.Request captured;
    final service = _service((request) async {
      captured = request;
      return http.Response(jsonEncode(_dashboardJson()), 200);
    });

    await service.getMonthly(year: 2025, month: 12);

    expect(captured.url.queryParameters, {'year': '2025', 'month': '12'});
    expect(captured.url.queryParameters, isNot(contains('userId')));
  });

  test(
    'monthly analysis calls only SmartBudget backend with empty default body',
    () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode(_analysisJson())),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final response = await service.getMonthlyAnalysis();

      expect(captured.url.host, 'api.example.test');
      expect(captured.url.path, '/api/ai/monthly-summary');
      expect(jsonDecode(captured.body), <String, Object?>{});
      expect(captured.body, isNot(contains('userId')));
      expect(response.analysis, 'Kontrollü aylık analiz.');
    },
  );

  test(
    'selected period is sent in monthly analysis body without user id',
    () async {
      late http.Request captured;
      final service = _service((request) async {
        captured = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode(_analysisJson())),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      await service.getMonthlyAnalysis(year: 2026, month: 8);

      expect(jsonDecode(captured.body), {'year': 2026, 'month': 8});
      expect(captured.body, isNot(contains('userId')));
    },
  );

  test(
    'monthly analysis uses the longer AI timeout, unlike the regular dashboard request',
    () async {
      // The client's own default timeout is intentionally tiny; only a
      // request that overrides it with ApiConfig.aiTimeout can survive the
      // slow response below.
      final service = DashboardService(
        apiClient: ApiClient(
          baseUrl: 'https://api.example.test',
          tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
          timeout: const Duration(milliseconds: 30),
          httpClient: MockClient((request) async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
            return http.Response.bytes(
              utf8.encode(jsonEncode(_analysisJson())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );

      final response = await service.getMonthlyAnalysis();

      expect(response.analysis, 'Kontrollü aylık analiz.');
    },
  );

  test(
    'regular dashboard request does not get the longer AI timeout',
    () async {
      final service = DashboardService(
        apiClient: ApiClient(
          baseUrl: 'https://api.example.test',
          tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
          timeout: const Duration(milliseconds: 30),
          httpClient: MockClient((request) async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
            return http.Response(jsonEncode(_dashboardJson()), 200);
          }),
        ),
      );

      await expectLater(
        service.getMonthly(),
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
}

DashboardService _service(
  Future<http.Response> Function(http.Request request) handler,
) {
  return DashboardService(
    apiClient: ApiClient(
      baseUrl: 'https://api.example.test',
      tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
      httpClient: MockClient(handler),
    ),
  );
}

Map<String, Object?> _dashboardJson() => {
  'year': 2026,
  'month': 8,
  'totalIncome': 5000,
  'totalExpense': 2500,
  'balance': 2500,
  'categoryExpenses': [
    {
      'categoryId': '11111111-1111-1111-1111-111111111111',
      'categoryName': 'Market',
      'amount': 2500,
      'percentageOfTotalExpense': 100,
    },
  ],
  'budgetUsages': [
    {
      'budgetId': '22222222-2222-2222-2222-222222222222',
      'category': {
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Market',
      },
      'limitAmount': 3000,
      'spentAmount': 2500,
      'usagePercent': 83.33,
      'alertStatus': 'Warning',
    },
  ],
  'previousMonthExpenseChangePercent': null,
  'highestSpendingCategory': null,
  'highestIncreaseCategory': null,
  'lastSixMonthsTrend': <Object?>[],
};

Map<String, Object?> _analysisJson() => {
  'success': true,
  'year': 2026,
  'month': 8,
  'analysis': 'Kontrollü aylık analiz.',
  'requiresManualReview': false,
  'message': 'Analiz oluşturuldu.',
};
