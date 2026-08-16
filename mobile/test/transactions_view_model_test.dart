import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/transaction_models.dart';
import 'package:smartbudget_mobile/screens/transactions/transactions_view_model.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'loads expense, income and categories and combines deterministically',
    () async {
      final expenses = FakeExpenseService(
        items: [
          sampleExpense(
            id: 'expense-later-created',
            date: DateTime(2026, 8, 16),
            createdAt: DateTime.utc(2026, 8, 16, 13),
          ),
        ],
      );
      final incomes = FakeIncomeService(
        items: [
          sampleIncome(
            id: 'income-same-date',
            date: DateTime(2026, 8, 16),
            createdAt: DateTime.utc(2026, 8, 16, 12),
          ),
          sampleIncome(id: 'income-older', date: DateTime(2026, 8, 15)),
        ],
      );
      final categories = FakeCategoryService();
      final model = _model(expenses, incomes, categories);

      await model.loadInitial();

      expect(expenses.getAllCalls, 1);
      expect(incomes.getAllCalls, 1);
      expect(categories.getAllCalls, 1);
      expect(model.visibleTransactions.map((item) => item.id), [
        'expense-later-created',
        'income-same-date',
        'income-older',
      ]);
    },
  );

  test('all, expense and income filters expose only requested types', () async {
    final model = _model(
      FakeExpenseService(items: [sampleExpense()]),
      FakeIncomeService(items: [sampleIncome()]),
      FakeCategoryService(),
    );
    await model.loadInitial();
    expect(model.visibleTransactions, hasLength(2));

    model.setFilter(TransactionFilter.expenses);
    expect(model.visibleTransactions.single.type, TransactionType.expense);

    model.setFilter(TransactionFilter.incomes);
    expect(model.visibleTransactions.single.type, TransactionType.income);
  });

  test('loading error and retry are controlled', () async {
    final completer = Completer<List<ExpenseListItem>>();
    final expenses = FakeExpenseService()
      ..getAllHandler = () => completer.future;
    final incomes = FakeIncomeService();
    final model = _model(expenses, incomes, FakeCategoryService());

    final load = model.loadInitial();
    expect(model.isLoading, isTrue);
    completer.completeError(
      const ApiException(ApiErrorType.network, 'Bağlantı kurulamadı.'),
    );
    await load;
    expect(model.errorMessage, 'Bağlantı kurulamadı.');

    expenses.getAllHandler = () async => [];
    await model.retry();
    expect(model.errorMessage, isNull);
    expect(expenses.getAllCalls, 2);
  });

  test(
    'refresh reloads both lists without refetching cached categories',
    () async {
      final expenses = FakeExpenseService();
      final incomes = FakeIncomeService();
      final categories = FakeCategoryService();
      final model = _model(expenses, incomes, categories);
      await model.loadInitial();

      await model.refresh();

      expect(expenses.getAllCalls, 2);
      expect(incomes.getAllCalls, 2);
      expect(categories.getAllCalls, 1);
    },
  );

  test(
    'successful expense and income deletes remove presentation items',
    () async {
      final expenses = FakeExpenseService(items: [sampleExpense()]);
      final incomes = FakeIncomeService(items: [sampleIncome()]);
      final model = _model(expenses, incomes, FakeCategoryService());
      await model.loadInitial();

      await model.deleteTransaction(
        model.visibleTransactions.firstWhere(
          (item) => item.type == TransactionType.expense,
        ),
      );
      await model.deleteTransaction(
        model.visibleTransactions.firstWhere(
          (item) => item.type == TransactionType.income,
        ),
      );

      expect(model.visibleTransactions, isEmpty);
      expect(expenses.deletedIds, ['expense-1']);
      expect(incomes.deletedIds, ['income-1']);
    },
  );

  test('delete 404 returns friendly message and refreshes lists', () async {
    final expenses = FakeExpenseService(items: [sampleExpense()])
      ..deleteHandler = (_) async => throw const ApiException(
        ApiErrorType.notFound,
        'İstenen kayıt bulunamadı.',
        statusCode: 404,
      );
    final incomes = FakeIncomeService();
    final model = _model(expenses, incomes, FakeCategoryService());
    await model.loadInitial();

    final message = await model.deleteTransaction(
      model.visibleTransactions.single,
    );

    expect(message, 'Kayıt bulunamadı veya artık mevcut değil.');
    expect(expenses.getAllCalls, 2);
    expect(incomes.getAllCalls, 2);
  });
}

TransactionsViewModel _model(
  FakeExpenseService expenses,
  FakeIncomeService incomes,
  FakeCategoryService categories,
) => TransactionsViewModel(
  expenseService: expenses,
  incomeService: incomes,
  categoryService: categories,
  recurringRuleService: FakeRecurringRuleService(),
);
