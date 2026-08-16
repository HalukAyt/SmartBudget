import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/config/app_theme.dart';
import 'package:smartbudget_mobile/models/transaction_models.dart';
import 'package:smartbudget_mobile/screens/transactions/transactions_screen.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('transaction screen shows loading then both lists', (
    tester,
  ) async {
    final completer = Completer<List<ExpenseListItem>>();
    final expenses = FakeExpenseService()
      ..getAllHandler = () => completer.future;
    final incomes = FakeIncomeService(items: [sampleIncome()]);
    await _pumpTransactions(tester, expenses: expenses, incomes: incomes);

    expect(find.text('İşlemler yükleniyor…'), findsOneWidget);
    completer.complete([sampleExpense()]);
    await tester.pumpAndSettle();

    expect(find.text('Market alışverişi'), findsOneWidget);
    expect(find.text('Maaş'), findsOneWidget);
    expect(find.textContaining('Gider • Market'), findsOneWidget);
    expect(find.textContaining('Gelir •'), findsOneWidget);
  });

  testWidgets('filters show all, only expenses or only incomes', (
    tester,
  ) async {
    await _pumpTransactions(
      tester,
      expenses: FakeExpenseService(items: [sampleExpense()]),
      incomes: FakeIncomeService(items: [sampleIncome()]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Market alışverişi'), findsOneWidget);
    expect(find.text('Maaş'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-expenses')));
    await tester.pump();
    expect(find.text('Market alışverişi'), findsOneWidget);
    expect(find.text('Maaş'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-incomes')));
    await tester.pump();
    expect(find.text('Market alışverişi'), findsNothing);
    expect(find.text('Maaş'), findsOneWidget);
  });

  testWidgets('empty state and add action are available', (tester) async {
    await _pumpTransactions(tester);
    await tester.pumpAndSettle();

    expect(find.text('Henüz işlem kaydın bulunmuyor.'), findsOneWidget);
    expect(find.text('İşlem Ekle'), findsWidgets);
  });

  testWidgets('error state retries transaction loading', (tester) async {
    var attempt = 0;
    final expenses = FakeExpenseService()
      ..getAllHandler = () async {
        attempt++;
        if (attempt == 1) {
          throw const ApiException(
            ApiErrorType.network,
            'Bağlantı kurulamadı.',
          );
        }
        return [];
      };
    await _pumpTransactions(tester, expenses: expenses);
    await tester.pumpAndSettle();
    expect(find.text('Bağlantı kurulamadı.'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz işlem kaydın bulunmuyor.'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads expense and income only', (
    tester,
  ) async {
    final expenses = FakeExpenseService(items: [sampleExpense()]);
    final incomes = FakeIncomeService(items: [sampleIncome()]);
    final categories = FakeCategoryService();
    await _pumpTransactions(
      tester,
      expenses: expenses,
      incomes: incomes,
      categories: categories,
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('transactions-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    expect(expenses.getAllCalls, 2);
    expect(incomes.getAllCalls, 2);
    expect(categories.getAllCalls, 1);
  });

  testWidgets('expense delete requires confirmation and removes item', (
    tester,
  ) async {
    final expenses = FakeExpenseService(items: [sampleExpense()]);
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      expenses: expenses,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gider kaydını sil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu işlem kaydını silmek istediğinizden emin misiniz?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(expenses.deletedIds, ['expense-1']);
    expect(financialChanges, 1);
    expect(find.text('Market alışverişi'), findsNothing);
  });

  testWidgets('income delete requires confirmation and removes item', (
    tester,
  ) async {
    final incomes = FakeIncomeService(items: [sampleIncome()]);
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      incomes: incomes,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gelir kaydını sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(incomes.deletedIds, ['income-1']);
    expect(financialChanges, 1);
    expect(find.text('Maaş'), findsNothing);
  });

  testWidgets('successful expense create returns and refreshes both lists', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    final incomes = FakeIncomeService();
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      expenses: expenses,
      incomes: incomes,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-option')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '125,50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Yeni gider');
    await tester.tap(find.byKey(const Key('expense-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gideri Kaydet'));
    await tester.tap(find.text('Gideri Kaydet'));
    await tester.pumpAndSettle();

    expect(expenses.createCalls, 1);
    expect(expenses.getAllCalls, 2);
    expect(incomes.getAllCalls, 2);
    expect(financialChanges, 1);
    expect(find.text('Yeni gider'), findsOneWidget);
  });

  testWidgets('successful income create returns and refreshes both lists', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    final incomes = FakeIncomeService();
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      expenses: expenses,
      incomes: incomes,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-option')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '5000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Ek gelir');
    await tester.tap(find.byKey(const Key('income-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Geliri Kaydet'));
    await tester.tap(find.text('Geliri Kaydet'));
    await tester.pumpAndSettle();

    expect(incomes.createCalls, 1);
    expect(expenses.getAllCalls, 2);
    expect(incomes.getAllCalls, 2);
    expect(financialChanges, 1);
    expect(find.text('Ek gelir'), findsOneWidget);
  });

  testWidgets('recurring income create still reports a financial change '
      '(rule may already be due and auto-realized by the backend)', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    final incomes = FakeIncomeService();
    final rules = FakeRecurringRuleService();
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      expenses: expenses,
      incomes: incomes,
      rules: rules,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-income-option')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '45000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Maaş');
    await tester.tap(find.byKey(const Key('income-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurrence-monthly')));
    await tester.pump();
    await tester.ensureVisible(find.text('Geliri Kaydet'));
    await tester.tap(find.text('Geliri Kaydet'));
    await tester.pumpAndSettle();

    expect(incomes.createCalls, 0);
    expect(rules.createCalls, 1);
    expect(financialChanges, 1);
    expect(expenses.getAllCalls, 2);
    expect(incomes.getAllCalls, 2);
  });

  testWidgets('recurring expense create still reports a financial change '
      '(rule may already be due and auto-realized by the backend)', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    final incomes = FakeIncomeService();
    final rules = FakeRecurringRuleService();
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      expenses: expenses,
      incomes: incomes,
      rules: rules,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense-option')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '20000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Kira');
    await tester.tap(find.byKey(const Key('expense-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurrence-monthly')));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('Gideri Kaydet'),
      find.byType(Scrollable).first,
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gideri Kaydet'));
    await tester.pumpAndSettle();

    expect(expenses.createCalls, 0);
    expect(rules.createCalls, 1);
    expect(financialChanges, 1);
    expect(expenses.getAllCalls, 2);
    expect(incomes.getAllCalls, 2);
  });

  testWidgets('failed expense create does not report a financial change', (
    tester,
  ) async {
    final expenses = FakeExpenseService()
      ..createHandler = (_) async => throw const ApiException(
        ApiErrorType.validation,
        'Gider kaydedilemedi.',
        statusCode: 400,
      );
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      expenses: expenses,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await _openExpenseForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '125,50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Yeni gider');
    await tester.tap(find.byKey(const Key('expense-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gideri Kaydet'));
    await tester.tap(find.text('Gideri Kaydet'));
    await tester.pumpAndSettle();

    expect(expenses.createCalls, 1);
    expect(financialChanges, 0);
  });

  testWidgets('AI suggestion alone does not report a financial change', (
    tester,
  ) async {
    final ai = FakeAiCategorizationService();
    var financialChanges = 0;
    await _pumpTransactions(
      tester,
      ai: ai,
      onFinancialDataChanged: () => financialChanges++,
    );
    await tester.pumpAndSettle();

    await _openExpenseForm(tester);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Market alışverişi',
    );
    await tester.ensureVisible(find.byKey(const Key('ai-category-button')));
    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.pumpAndSettle();

    expect(ai.calls, 1);
    expect(financialChanges, 0);
  });

  testWidgets('delete 404 displays ownership-safe friendly message', (
    tester,
  ) async {
    final expenses = FakeExpenseService(items: [sampleExpense()])
      ..deleteHandler = (_) async => throw const ApiException(
        ApiErrorType.notFound,
        'İstenen kayıt bulunamadı.',
        statusCode: 404,
      );
    await _pumpTransactions(tester, expenses: expenses);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gider kaydını sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(
      find.text('Kayıt bulunamadı veya artık mevcut değil.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpTransactions(
  WidgetTester tester, {
  FakeExpenseService? expenses,
  FakeIncomeService? incomes,
  FakeCategoryService? categories,
  FakeAiCategorizationService? ai,
  FakeRecurringRuleService? rules,
  VoidCallback? onFinancialDataChanged,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: TransactionsScreen(
      expenseService: expenses ?? FakeExpenseService(),
      incomeService: incomes ?? FakeIncomeService(),
      categoryService: categories ?? FakeCategoryService(),
      aiService: ai ?? FakeAiCategorizationService(),
      recurringRuleService: rules ?? FakeRecurringRuleService(),
      onFinancialDataChanged: onFinancialDataChanged,
    ),
  ),
);

Future<void> _openExpenseForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('add-transaction')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-expense-option')));
  await tester.pumpAndSettle();
}
