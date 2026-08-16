import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/budget_models.dart';
import 'package:smartbudget_mobile/screens/budgets/budgets_view_model.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'loads budgets/categories and filters selected period for presentation',
    () async {
      final budgets = FakeBudgetService(
        items: [
          sampleBudget(id: 'august', month: 8, year: 2026),
          sampleBudget(id: 'july', month: 7, year: 2026),
          sampleBudget(id: 'other-year', month: 8, year: 2025),
        ],
      );
      final categories = FakeCategoryService();
      final model = _model(budgets, categories);

      await model.loadInitial();
      expect(model.visibleBudgets.map((item) => item.id), ['august']);
      expect(budgets.getAllCalls, 1);
      expect(categories.getAllCalls, 1);

      model.selectPeriod(year: 2026, month: 7);
      expect(model.visibleBudgets.map((item) => item.id), ['july']);
      expect(budgets.getAllCalls, 1);
    },
  );

  test('invalid period is ignored', () async {
    final model = _model(FakeBudgetService(), FakeCategoryService());
    model.selectPeriod(year: 1999, month: 13);
    expect(model.selectedYear, 2026);
    expect(model.selectedMonth, 8);
  });

  test(
    'without explicit period first backend budget period is selected',
    () async {
      final model = BudgetsViewModel(
        budgetService: FakeBudgetService(
          items: [sampleBudget(month: 11, year: 2025)],
        ),
        categoryService: FakeCategoryService(),
      );

      await model.loadInitial();

      expect(model.selectedYear, 2025);
      expect(model.selectedMonth, 11);
      expect(model.visibleBudgets, hasLength(1));
    },
  );

  test('loading error and retry are controlled', () async {
    final completer = Completer<List<BudgetListItem>>();
    final budgets = FakeBudgetService()..getAllHandler = () => completer.future;
    final model = _model(budgets, FakeCategoryService());

    final load = model.loadInitial();
    expect(model.isLoading, isTrue);
    completer.completeError(
      const ApiException(ApiErrorType.network, 'Bağlantı kurulamadı.'),
    );
    await load;
    expect(model.errorMessage, 'Bağlantı kurulamadı.');

    budgets.getAllHandler = () async => [];
    await model.retry();
    expect(model.errorMessage, isNull);
    expect(budgets.getAllCalls, 2);
  });

  test('refresh reloads budgets without refetching categories', () async {
    final budgets = FakeBudgetService();
    final categories = FakeCategoryService();
    final model = _model(budgets, categories);
    await model.loadInitial();

    await model.refresh();

    expect(budgets.getAllCalls, 2);
    expect(categories.getAllCalls, 1);
  });

  test('successful delete removes budget and 404 refreshes safely', () async {
    final budgets = FakeBudgetService(items: [sampleBudget()]);
    final model = _model(budgets, FakeCategoryService());
    await model.loadInitial();

    expect(await model.deleteBudget(model.visibleBudgets.single), isNull);
    expect(model.visibleBudgets, isEmpty);

    budgets.items = [sampleBudget(id: 'missing')];
    budgets.deleteHandler = (_) async => throw const ApiException(
      ApiErrorType.notFound,
      'Not found',
      statusCode: 404,
    );
    await model.refresh();
    final message = await model.deleteBudget(model.visibleBudgets.single);

    expect(message, 'Bütçe kaydı bulunamadı veya artık mevcut değil.');
    expect(budgets.getAllCalls, 3);
  });
}

BudgetsViewModel _model(
  FakeBudgetService budgets,
  FakeCategoryService categories,
) => BudgetsViewModel(
  budgetService: budgets,
  categoryService: categories,
  initialYear: 2026,
  initialMonth: 8,
);
