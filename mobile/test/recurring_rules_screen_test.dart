import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/models/recurring_models.dart';
import 'package:smartbudget_mobile/screens/bills/bills_screen.dart';
import 'package:smartbudget_mobile/screens/transactions/transactions_screen.dart';

import 'helpers/fakes.dart';

// Wide enough window that any test-run date is considered "due" without
// depending on the current calendar month.
final _alwaysDueStart = DateTime(2000, 1, 1);
final _alwaysDueEnd = DateTime(2100, 12, 1);

void main() {
  group('Transactions - Planlananlar', () {
    testWidgets('planned tab lists income/expense rules, not bill rules', (
      tester,
    ) async {
      final rules = FakeRecurringRuleService(
        items: [
          sampleRecurringRule(
            id: 'income-rule',
            recordType: RecurringRecordType.income,
            description: 'Maaş',
            startDate: _alwaysDueStart,
            endDate: _alwaysDueEnd,
          ),
          sampleRecurringRule(
            id: 'bill-rule',
            recordType: RecurringRecordType.bill,
            description: null,
            billType: BillType.electricity,
            amount: null,
            startDate: _alwaysDueStart,
            endDate: _alwaysDueEnd,
          ),
        ],
      );
      await tester.pumpWidget(_transactionsApp(rules: rules));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter-planned')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('recurring-rule-income-rule')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recurring-rule-bill-rule')), findsNothing);
      expect(rules.getAllCalls, 1);
    });

    testWidgets('empty state is shown when there are no planned records', (
      tester,
    ) async {
      await tester.pumpWidget(_transactionsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter-planned')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Henüz planlanan bir gelir veya gider'),
        findsOneWidget,
      );
    });

    testWidgets(
      'pending income rule shows a status label with no mandatory button',
      (tester) async {
        final rules = FakeRecurringRuleService(
          items: [
            sampleRecurringRule(
              id: 'income-rule',
              recordType: RecurringRecordType.income,
              description: 'Maaş',
              amount: 45000,
              startDate: _alwaysDueStart,
              endDate: _alwaysDueEnd,
              nextDueDate: DateTime(2026, 9, 16),
            ),
          ],
        );
        await tester.pumpWidget(_transactionsApp(rules: rules));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('filter-planned')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('realize-rule-income-rule')), findsNothing);
        expect(find.text('Bu Ay İçin Oluştur'), findsNothing);
        expect(find.textContaining('Bekleniyor'), findsOneWidget);
        expect(find.textContaining('Sonraki: 16 Eylül 2026'), findsOneWidget);
      },
    );

    testWidgets(
      'pending expense rule shows a status label with no mandatory button',
      (tester) async {
        final rules = FakeRecurringRuleService(
          items: [
            sampleRecurringRule(
              id: 'expense-rule',
              recordType: RecurringRecordType.expense,
              description: 'Kira',
              amount: 20000,
              startDate: _alwaysDueStart,
              endDate: _alwaysDueEnd,
              nextDueDate: DateTime(2026, 9, 5),
            ),
          ],
        );
        await tester.pumpWidget(_transactionsApp(rules: rules));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('filter-planned')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('realize-rule-expense-rule')),
          findsNothing,
        );
        expect(find.textContaining('Bekleniyor'), findsOneWidget);
        expect(find.textContaining('Sonraki: 5 Eylül 2026'), findsOneWidget);
      },
    );

    testWidgets('realized-this-month income rule shows Gerçekleşti', (
      tester,
    ) async {
      final rules = FakeRecurringRuleService(
        items: [
          sampleRecurringRule(
            id: 'income-rule',
            recordType: RecurringRecordType.income,
            startDate: _alwaysDueStart,
            endDate: _alwaysDueEnd,
            isRealizedThisMonth: true,
          ),
        ],
      );
      await tester.pumpWidget(_transactionsApp(rules: rules));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-planned')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('realize-rule-income-rule')), findsNothing);
      expect(find.textContaining('Gerçekleşti'), findsOneWidget);
    });
  });

  group('Bills - Planlanan Faturalar', () {
    testWidgets('due bill rule opens an amount form and realizes', (
      tester,
    ) async {
      var financialChanges = 0;
      final bills = FakeBillService(trend: sampleBillTrend());
      final rules = FakeRecurringRuleService(
        items: [
          sampleRecurringRule(
            id: 'bill-rule',
            recordType: RecurringRecordType.bill,
            description: null,
            amount: null,
            billType: BillType.electricity,
            startDate: _alwaysDueStart,
            endDate: _alwaysDueEnd,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BillsScreen(
            service: bills,
            recurringRuleService: rules,
            onFinancialDataChanged: () => financialChanges++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialBillCalls = bills.getAllCalls;
      final initialTrendCalls = bills.getTrendCalls;

      expect(find.text('Faturayı Gir'), findsOneWidget);
      expect(find.text('Bu Ay İçin Oluştur'), findsNothing);
      await tester.tap(find.byKey(const Key('realize-bill-rule-bill-rule')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('realize-bill-amount')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('realize-bill-amount')),
        '750',
      );
      await tester.tap(find.byKey(const Key('confirm-realize-bill')));
      await tester.pumpAndSettle();

      expect(rules.realizeCalls, 1);
      expect(rules.lastRealizeRequest?.amount, 750);
      expect(financialChanges, 1);
      expect(bills.getAllCalls, greaterThan(initialBillCalls));
      expect(bills.getTrendCalls, greaterThan(initialTrendCalls));
    });

    testWidgets(
      'fixed-amount bill rule shows Bekleniyor with no manual action',
      (tester) async {
        final rules = FakeRecurringRuleService(
          items: [
            sampleRecurringRule(
              id: 'bill-rule',
              recordType: RecurringRecordType.bill,
              amount: 750,
              billType: BillType.electricity,
              startDate: _alwaysDueStart,
              endDate: _alwaysDueEnd,
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: BillsScreen(
              service: FakeBillService(),
              recurringRuleService: rules,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('realize-bill-rule-bill-rule')),
          findsNothing,
        );
        expect(find.text('Faturayı Gir'), findsNothing);
        expect(find.text('Bekleniyor'), findsOneWidget);
      },
    );

    testWidgets('bill realize requires a positive amount', (tester) async {
      final rules = FakeRecurringRuleService(
        items: [
          sampleRecurringRule(
            id: 'bill-rule',
            recordType: RecurringRecordType.bill,
            amount: null,
            billType: BillType.water,
            startDate: _alwaysDueStart,
            endDate: _alwaysDueEnd,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BillsScreen(
            service: FakeBillService(),
            recurringRuleService: rules,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('realize-bill-rule-bill-rule')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-realize-bill')));
      await tester.pump();

      expect(find.text('Geçerli bir tutar girin.'), findsOneWidget);
      expect(rules.realizeCalls, 0);
    });
  });
}

Widget _transactionsApp({
  FakeRecurringRuleService? rules,
  VoidCallback? onFinancialDataChanged,
}) => MaterialApp(
  home: TransactionsScreen(
    expenseService: FakeExpenseService(),
    incomeService: FakeIncomeService(),
    categoryService: FakeCategoryService(),
    aiService: FakeAiCategorizationService(),
    recurringRuleService: rules ?? FakeRecurringRuleService(),
    onFinancialDataChanged: onFinancialDataChanged,
  ),
);
