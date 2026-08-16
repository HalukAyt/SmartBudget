import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/config/app_theme.dart';
import 'package:smartbudget_mobile/models/transaction_models.dart';
import 'package:smartbudget_mobile/screens/transactions/add_expense_screen.dart';
import 'package:smartbudget_mobile/screens/transactions/add_income_screen.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets(
    'expense form rejects missing amount, description, category and date',
    (tester) async {
      await _pumpExpense(tester);
      await _tapVisible(tester, find.text('Gideri Kaydet'));

      expect(find.text('Tutar zorunludur.'), findsOneWidget);
      expect(find.text('Açıklama zorunludur.'), findsOneWidget);
      expect(find.text('Kategori seçmelisiniz.'), findsOneWidget);
      expect(find.text('Tarih zorunludur.'), findsOneWidget);
    },
  );

  testWidgets('AI button validates description without calling service', (
    tester,
  ) async {
    final ai = FakeAiCategorizationService();
    await _pumpExpense(tester, ai: ai);

    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.pump();

    expect(ai.calls, 0);
    expect(find.byKey(const Key('ai-category-error')), findsOneWidget);
  });

  testWidgets('AI success is not selected until explicit user acceptance', (
    tester,
  ) async {
    final ai = FakeAiCategorizationService()
      ..handler = (_) async => const CategorizeExpenseResponse(
        success: true,
        categoryId: 'category-market',
        category: 'Market',
        confidence: null,
        requiresManualSelection: false,
        message: 'Öneri oluşturuldu.',
      );
    await _pumpExpense(tester, ai: ai);
    await tester.enterText(find.byType(TextFormField).at(1), '  Migros  ');

    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.pumpAndSettle();

    expect(ai.lastDescription, 'Migros');
    expect(find.text('AI Önerisi'), findsOneWidget);
    expect(find.text('Öneriyi Kullan'), findsOneWidget);
    expect(find.textContaining('Güven:'), findsNothing);
    final field = tester.state<FormFieldState<String>>(
      find.descendant(
        of: find.byKey(const Key('expense-category')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    expect(field.value, isNull);

    await tester.tap(find.byKey(const Key('accept-ai-category')));
    await tester.pump();
    expect(field.value, 'category-market');
  });

  testWidgets('accepted AI suggestion creates expense with AI flag true', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    await _pumpExpense(tester, expenses: expenses);
    await _fillExpenseBasics(tester);
    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-ai-category')));

    await _tapVisible(tester, find.text('Gideri Kaydet'));
    await tester.pumpAndSettle();

    expect(expenses.createCalls, 1);
    expect(expenses.lastCreateRequest?.categoryId, 'category-market');
    expect(expenses.lastCreateRequest?.isAiCategorized, isTrue);
  });

  testWidgets('manual category change after AI acceptance clears AI flag', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    await _pumpExpense(tester, expenses: expenses);
    await _fillExpenseBasics(tester);
    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accept-ai-category')));
    await tester.pump();

    await _selectCategory(tester, 'Ulaşım');
    await _tapVisible(tester, find.text('Gideri Kaydet'));
    await tester.pumpAndSettle();

    expect(expenses.lastCreateRequest?.categoryId, 'category-transport');
    expect(expenses.lastCreateRequest?.isAiCategorized, isFalse);
  });

  testWidgets('AI failure keeps manual expense creation available', (
    tester,
  ) async {
    final expenses = FakeExpenseService();
    final ai = FakeAiCategorizationService()
      ..handler = (_) async => const CategorizeExpenseResponse(
        success: false,
        categoryId: null,
        category: null,
        confidence: null,
        requiresManualSelection: true,
        message: 'Manuel seçim gerekli.',
      );
    await _pumpExpense(tester, expenses: expenses, ai: ai);
    await _fillExpenseBasics(tester, selectCategory: false);
    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'AI şu anda kategori öneremedi. Kategoriyi manuel olarak seçebilirsin.',
      ),
      findsOneWidget,
    );
    expect(expenses.createCalls, 0);
    await _selectCategory(tester, 'Market');
    await _tapVisible(tester, find.text('Gideri Kaydet'));
    await tester.pumpAndSettle();
    expect(expenses.createCalls, 1);
    expect(expenses.lastCreateRequest?.isAiCategorized, isFalse);
  });

  testWidgets('AI double submit is blocked and form remains usable', (
    tester,
  ) async {
    final completer = Completer<CategorizeExpenseResponse>();
    final ai = FakeAiCategorizationService()..handler = (_) => completer.future;
    await _pumpExpense(tester, ai: ai);
    await tester.enterText(find.byType(TextFormField).at(1), 'Market');

    await tester.tap(find.byKey(const Key('ai-category-button')));
    await tester.tap(
      find.byKey(const Key('ai-category-button')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(ai.calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(Exception('AI unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Gideri Kaydet'), findsOneWidget);
  });

  testWidgets('income form validates amount and date', (tester) async {
    await _pumpIncome(tester);
    await _tapVisible(tester, find.text('Geliri Kaydet'));

    expect(find.text('Tutar zorunludur.'), findsOneWidget);
    expect(find.text('Tarih zorunludur.'), findsOneWidget);
  });

  testWidgets(
    'income create sends null for empty description and date-only value',
    (tester) async {
      final incomes = FakeIncomeService();
      await _pumpIncome(tester, incomes: incomes);
      await tester.enterText(find.byType(TextFormField).first, '5000,50');
      await _selectDate(tester, const Key('income-date'));

      await _tapVisible(tester, find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();

      expect(incomes.createCalls, 1);
      expect(incomes.lastCreateRequest?.description, isNull);
      expect(incomes.lastCreateRequest?.amount, 5000.5);
      expect(incomes.lastCreateRequest?.toJson(), isNot(contains('userId')));
    },
  );
}

Future<void> _pumpExpense(
  WidgetTester tester, {
  FakeExpenseService? expenses,
  FakeAiCategorizationService? ai,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: AddExpenseScreen(
      categories: sampleCategories,
      expenseService: expenses ?? FakeExpenseService(),
      aiService: ai ?? FakeAiCategorizationService(),
      recurringRuleService: FakeRecurringRuleService(),
    ),
  ),
);

Future<void> _pumpIncome(WidgetTester tester, {FakeIncomeService? incomes}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddIncomeScreen(
          incomeService: incomes ?? FakeIncomeService(),
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );

Future<void> _fillExpenseBasics(
  WidgetTester tester, {
  bool selectCategory = true,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), '1250,50');
  await tester.enterText(find.byType(TextFormField).at(1), 'Market alışverişi');
  await _selectDate(tester, const Key('expense-date'));
  if (selectCategory) await _selectCategory(tester, 'Market');
}

Future<void> _selectDate(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _selectCategory(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('expense-category')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}
