import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/models/budget_models.dart';
import 'package:smartbudget_mobile/models/dashboard_models.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/budget_service.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'budget response parses all alert states and preserves over 100 usage',
    () {
      for (final scenario in const [
        ('Normal', BudgetAlertStatus.normal),
        ('Warning', BudgetAlertStatus.warning),
        ('Exceeded', BudgetAlertStatus.exceeded),
        ('FutureValue', BudgetAlertStatus.unknown),
      ]) {
        final budget = BudgetListItem.fromJson(
          _budgetJson(alertStatus: scenario.$1),
        );
        expect(budget.alertStatus, scenario.$2);
        expect(budget.usagePercent, 135);
      }
    },
  );

  test(
    'create request excludes user id and list/create use correct endpoints',
    () async {
      final requests = <http.Request>[];
      final service = _service((request) async {
        requests.add(request);
        return request.method == 'GET'
            ? _jsonResponse([_budgetJson()])
            : _jsonResponse(_budgetJson());
      });

      await service.getAll();
      await service.create(
        const CreateBudgetRequest(
          categoryId: 'category-market',
          limitAmount: 2000,
          month: 8,
          year: 2026,
        ),
      );

      expect(requests[0].method, 'GET');
      expect(requests[0].url.path, '/api/budgets');
      expect(requests[1].method, 'POST');
      expect(requests[1].url.path, '/api/budgets');
      expect(jsonDecode(requests[1].body), {
        'categoryId': 'category-market',
        'limitAmount': 2000.0,
        'month': 8,
        'year': 2026,
      });
      expect(requests[1].body, isNot(contains('userId')));
    },
  );

  test('update sends only limitAmount and delete uses id route', () async {
    final requests = <http.Request>[];
    final service = _service((request) async {
      requests.add(request);
      return request.method == 'DELETE'
          ? http.Response('', 204)
          : _jsonResponse(_budgetJson(limitAmount: 3500));
    });

    final response = await service.update(
      'budget-1',
      const UpdateBudgetRequest(limitAmount: 3500),
    );
    await service.delete('budget-1');

    expect(requests[0].method, 'PUT');
    expect(requests[0].url.path, '/api/budgets/budget-1');
    expect(jsonDecode(requests[0].body), {'limitAmount': 3500.0});
    expect(requests[0].body, isNot(contains('categoryId')));
    expect(requests[0].body, isNot(contains('month')));
    expect(requests[0].body, isNot(contains('year')));
    expect(requests[0].body, isNot(contains('userId')));
    expect(response.limitAmount, 3500);
    expect(requests[1].method, 'DELETE');
    expect(requests[1].url.path, '/api/budgets/budget-1');
  });
}

BudgetService _service(
  Future<http.Response> Function(http.Request request) handler,
) => BudgetService(
  apiClient: ApiClient(
    baseUrl: 'https://api.example.test',
    tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
    httpClient: MockClient(handler),
  ),
);

http.Response _jsonResponse(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _budgetJson({
  String alertStatus = 'Exceeded',
  double limitAmount = 2000,
}) => {
  'id': 'budget-1',
  'category': {'id': 'category-market', 'name': 'Market'},
  'limitAmount': limitAmount,
  'month': 8,
  'year': 2026,
  'spentAmount': 2700,
  'usagePercent': 135,
  'alertStatus': alertStatus,
  'createdAt': '2026-08-01T10:00:00Z',
};
