import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/models/transaction_models.dart';
import 'package:smartbudget_mobile/services/ai_categorization_service.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/category_service.dart';
import 'package:smartbudget_mobile/services/expense_service.dart';
import 'package:smartbudget_mobile/services/income_service.dart';

import 'helpers/fakes.dart';

void main() {
  test('category and transaction lists parse backend contracts', () async {
    final requests = <String>[];
    final client = _client((request) async {
      requests.add(request.url.path);
      return switch (request.url.path) {
        '/api/categories' => _jsonResponse([
          {'id': 'category-market', 'name': 'Market'},
        ]),
        '/api/expenses' => _jsonResponse([_expenseJson()]),
        '/api/incomes' => _jsonResponse([_incomeJson()]),
        _ => http.Response('', 404),
      };
    });

    final categories = await CategoryService(apiClient: client).getAll();
    final expenses = await ExpenseService(apiClient: client).getAll();
    final incomes = await IncomeService(apiClient: client).getAll();

    expect(requests, ['/api/categories', '/api/expenses', '/api/incomes']);
    expect(categories.single.name, 'Market');
    expect(expenses.single.category.name, 'Market');
    expect(expenses.single.isAiCategorized, isTrue);
    expect(incomes.single.description, isNull);
  });

  test('expense create payload matches backend and excludes user id', () async {
    Map<String, Object?>? body;
    final service = ExpenseService(
      apiClient: _client((request) async {
        body = jsonDecode(request.body) as Map<String, Object?>;
        return _jsonResponse(_expenseJson());
      }),
    );

    await service.create(
      CreateExpenseRequest(
        amount: 1250.50,
        description: 'Market alışverişi',
        categoryId: 'category-market',
        date: DateTime(2026, 8, 16),
        isAiCategorized: true,
      ),
    );

    expect(body, {
      'amount': 1250.5,
      'description': 'Market alışverişi',
      'categoryId': 'category-market',
      'date': '2026-08-16',
      'isAiCategorized': true,
    });
    expect(body, isNot(contains('userId')));
  });

  test('income empty description is null and user id is absent', () async {
    Map<String, Object?>? body;
    final service = IncomeService(
      apiClient: _client((request) async {
        body = jsonDecode(request.body) as Map<String, Object?>;
        return _jsonResponse(_incomeJson());
      }),
    );

    await service.create(
      CreateIncomeRequest(
        amount: 5000,
        description: null,
        date: DateTime(2026, 8, 16),
      ),
    );

    expect(body, {'amount': 5000.0, 'description': null, 'date': '2026-08-16'});
    expect(body, isNot(contains('userId')));
  });

  test(
    'AI categorization uses backend only and sends trimmed description',
    () async {
      late http.Request captured;
      final service = AiCategorizationService(
        apiClient: _client((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'categoryId': 'category-market',
            'category': 'Market',
            'confidence': null,
            'requiresManualSelection': false,
            'message': 'Öneri oluşturuldu.',
          });
        }),
      );

      final result = await service.categorize('  Migros alışverişi  ');

      expect(captured.url.host, 'api.example.test');
      expect(captured.url.path, '/api/ai/categorize-expense');
      expect(jsonDecode(captured.body), {'description': 'Migros alışverişi'});
      expect(captured.body, isNot(contains('userId')));
      expect(result.confidence, isNull);
    },
  );

  test('expense and income delete use only id route', () async {
    final paths = <String>[];
    final client = _client((request) async {
      paths.add(request.url.path);
      return http.Response('', 204);
    });

    await ExpenseService(apiClient: client).delete('expense-id');
    await IncomeService(apiClient: client).delete('income-id');

    expect(paths, ['/api/expenses/expense-id', '/api/incomes/income-id']);
  });
}

ApiClient _client(
  Future<http.Response> Function(http.Request request) handler,
) => ApiClient(
  baseUrl: 'https://api.example.test',
  tokenStorage: MemoryTokenStorage()..token = 'jwt-token',
  httpClient: MockClient(handler),
);

http.Response _jsonResponse(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _expenseJson() => {
  'id': 'expense-1',
  'amount': 1250.5,
  'description': 'Market alışverişi',
  'category': {'id': 'category-market', 'name': 'Market'},
  'date': '2026-08-16',
  'createdAt': '2026-08-16T12:00:00Z',
  'isAiCategorized': true,
};

Map<String, Object?> _incomeJson() => {
  'id': 'income-1',
  'amount': 5000,
  'description': null,
  'date': '2026-08-15',
  'createdAt': '2026-08-15T12:00:00Z',
};
