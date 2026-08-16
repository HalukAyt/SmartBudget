import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/config/app_theme.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/models/recurring_models.dart';
import 'package:smartbudget_mobile/screens/bills/add_bill_screen.dart';
import 'package:smartbudget_mobile/screens/transactions/add_expense_screen.dart';
import 'package:smartbudget_mobile/screens/transactions/add_income_screen.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  group('Income', () {
    testWidgets('one-time selection uses the existing income endpoint', (
      tester,
    ) async {
      final incomes = FakeIncomeService();
      final rules = FakeRecurringRuleService();
      await _pumpIncome(tester, incomes: incomes, rules: rules);

      await tester.enterText(find.byType(TextFormField).first, '5000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();

      expect(incomes.createCalls, 1);
      expect(rules.createCalls, 0);
    });

    testWidgets('monthly selection uses the recurring endpoint instead', (
      tester,
    ) async {
      final incomes = FakeIncomeService();
      final rules = FakeRecurringRuleService();
      await _pumpIncome(tester, incomes: incomes, rules: rules);

      await tester.enterText(find.byType(TextFormField).first, '45000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();
      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();

      expect(incomes.createCalls, 0);
      expect(rules.createCalls, 1);
      expect(rules.lastCreateRequest?.recordType, RecurringRecordType.income);
      expect(rules.lastCreateRequest?.amount, 45000);
    });

    testWidgets('default duration is 6 months', (tester) async {
      await _pumpIncome(tester);
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('recurrence-duration-sixMonths')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('3 month selection is sent as durationMonths', (tester) async {
      final rules = FakeRecurringRuleService();
      await _pumpIncome(tester, rules: rules);
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('recurrence-duration-threeMonths')),
      );
      await tester.pump();
      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();

      expect(rules.lastCreateRequest?.durationMonths, 3);
    });

    testWidgets('12 month selection is sent as durationMonths', (tester) async {
      final rules = FakeRecurringRuleService();
      await _pumpIncome(tester, rules: rules);
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('recurrence-duration-twelveMonths')),
      );
      await tester.pump();
      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();

      expect(rules.lastCreateRequest?.durationMonths, 12);
    });

    testWidgets('custom end date requires a value before submit', (
      tester,
    ) async {
      final rules = FakeRecurringRuleService();
      await _pumpIncome(tester, rules: rules);
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('recurrence-duration-custom')));
      await tester.pump();

      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pump();
      expect(find.text('Bitiş tarihi zorunludur.'), findsOneWidget);
      expect(rules.createCalls, 0);

      await _selectDate(tester, const Key('recurrence-end-date'));
      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();
      expect(rules.createCalls, 1);
      expect(rules.lastCreateRequest?.durationMonths, isNull);
      expect(rules.lastCreateRequest?.endDate, isNotNull);
    });

    testWidgets('backend failure keeps form usable and shows an error', (
      tester,
    ) async {
      final rules = FakeRecurringRuleService()
        ..createHandler = (_) => throw const ApiException(
          ApiErrorType.validation,
          'Planlanan kayıt oluşturulamadı.',
        );
      await _pumpIncome(tester, rules: rules);
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();

      await tester.tap(find.text('Geliri Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Planlanan kayıt oluşturulamadı.'), findsOneWidget);
      expect(find.text('Geliri Kaydet'), findsOneWidget);
    });

    testWidgets('double submit does not create the rule twice', (tester) async {
      final completer = Completer<RecurringRuleListItem>();
      final rules = FakeRecurringRuleService()
        ..createHandler = (_) => completer.future;
      await _pumpIncome(tester, rules: rules);
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await _selectDate(tester, const Key('income-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();

      await tester.tap(find.text('Geliri Kaydet'));
      await tester.tap(find.text('Geliri Kaydet'), warnIfMissed: false);
      await tester.pump();
      expect(rules.createCalls, 1);

      completer.complete(sampleRecurringRule());
      await tester.pumpAndSettle();
    });
  });

  group('Expense', () {
    testWidgets('monthly selection uses the recurring endpoint instead', (
      tester,
    ) async {
      final expenses = FakeExpenseService();
      final rules = FakeRecurringRuleService();
      await _pumpExpense(tester, expenses: expenses, rules: rules);

      await tester.enterText(find.byType(TextFormField).at(0), '20000');
      await tester.enterText(find.byType(TextFormField).at(1), 'Ev kirası');
      await tester.tap(find.byKey(const Key('expense-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Market').last);
      await tester.pumpAndSettle();
      await _selectDate(tester, const Key('expense-date'));
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('recurrence-duration-twelveMonths')),
      );
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
      expect(rules.lastCreateRequest?.recordType, RecurringRecordType.expense);
      expect(rules.lastCreateRequest?.categoryId, 'category-market');
      expect(rules.lastCreateRequest?.durationMonths, 12);
    });
  });

  group('Bill', () {
    testWidgets('monthly selection allows an empty template amount', (
      tester,
    ) async {
      final bills = FakeBillService();
      final rules = FakeRecurringRuleService();
      await _pumpBill(tester, bills: bills, rules: rules);

      await tester.tap(find.byKey(const Key('bill-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elektrik').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bill-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();

      await tester.tap(find.text('Faturayı Kaydet'));
      await tester.pumpAndSettle();

      expect(bills.createCalls, 0);
      expect(rules.createCalls, 1);
      expect(rules.lastCreateRequest?.recordType, RecurringRecordType.bill);
      expect(rules.lastCreateRequest?.billType, BillType.electricity);
      expect(rules.lastCreateRequest?.amount, isNull);
    });

    testWidgets('one-time bill still requires a positive amount', (
      tester,
    ) async {
      final bills = FakeBillService();
      await _pumpBill(tester, bills: bills);

      await tester.tap(find.byKey(const Key('bill-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elektrik').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bill-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Faturayı Kaydet'));
      await tester.pump();

      expect(find.text('Tutar zorunludur.'), findsOneWidget);
      expect(bills.createCalls, 0);
    });
  });
}

Future<void> _pumpIncome(
  WidgetTester tester, {
  FakeIncomeService? incomes,
  FakeRecurringRuleService? rules,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: AddIncomeScreen(
      incomeService: incomes ?? FakeIncomeService(),
      recurringRuleService: rules ?? FakeRecurringRuleService(),
    ),
  ),
);

Future<void> _pumpExpense(
  WidgetTester tester, {
  FakeExpenseService? expenses,
  FakeRecurringRuleService? rules,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: AddExpenseScreen(
      categories: sampleCategories,
      expenseService: expenses ?? FakeExpenseService(),
      aiService: FakeAiCategorizationService(),
      recurringRuleService: rules ?? FakeRecurringRuleService(),
    ),
  ),
);

Future<void> _pumpBill(
  WidgetTester tester, {
  FakeBillService? bills,
  FakeRecurringRuleService? rules,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: AddBillScreen(
      service: bills ?? FakeBillService(),
      recurringRuleService: rules ?? FakeRecurringRuleService(),
    ),
  ),
);

Future<void> _selectDate(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
