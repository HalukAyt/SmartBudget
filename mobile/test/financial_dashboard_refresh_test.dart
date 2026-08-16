import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smartbudget_mobile/app.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets(
    'successful financial mutation refreshes Dashboard once with backend data',
    (tester) async {
      final storage = MemoryTokenStorage()
        ..token = 'jwt-token'
        ..email = 'refresh@example.com';
      await storage.markTutorialSeen('refresh@example.com');
      var dashboardLoad = 0;
      final dashboard = FakeDashboardService(
        monthlyHandler: ({year, month}) async {
          dashboardLoad++;
          return dashboardLoad == 1
              ? sampleDashboard(
                  totalIncome: 1000,
                  totalExpense: 250,
                  balance: 750,
                )
              : sampleDashboard(
                  totalIncome: 9000,
                  totalExpense: 250,
                  balance: 8750,
                );
        },
      );

      final expenses = FakeExpenseService(items: [sampleExpense()]);
      await _pumpApp(tester, storage, dashboard, expenses: expenses);
      expect(find.text('₺1.000,00'), findsOneWidget);
      expect(dashboard.monthlyCalls, hasLength(1));

      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      await _deleteExpense(tester);

      expect(dashboard.monthlyCalls, hasLength(2));
      await tester.tap(find.byType(NavigationDestination).at(0));
      await tester.pumpAndSettle();
      expect(find.text('₺9.000,00'), findsOneWidget);
      expect(find.text('₺8.750,00'), findsOneWidget);
    },
  );

  testWidgets(
    'Dashboard refresh failure does not undo successful financial mutation',
    (tester) async {
      final storage = MemoryTokenStorage()
        ..token = 'jwt-token'
        ..email = 'refresh-failure@example.com';
      await storage.markTutorialSeen('refresh-failure@example.com');
      var dashboardLoad = 0;
      final dashboard = FakeDashboardService(
        monthlyHandler: ({year, month}) async {
          dashboardLoad++;
          if (dashboardLoad > 1) throw Exception('Dashboard unavailable');
          return sampleDashboard();
        },
      );
      final expenses = FakeExpenseService(items: [sampleExpense()]);

      await _pumpApp(tester, storage, dashboard, expenses: expenses);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      await _deleteExpense(tester);

      expect(expenses.deletedIds, ['expense-1']);
      expect(find.text('Market alışverişi'), findsNothing);
      expect(dashboard.monthlyCalls, hasLength(2));
    },
  );

  testWidgets('successful bill delete refreshes Dashboard once', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'bill-refresh@example.com';
    await storage.markTutorialSeen('bill-refresh@example.com');
    final dashboard = FakeDashboardService();
    final bills = FakeBillService(items: [sampleBill()]);

    await _pumpApp(tester, storage, dashboard, bills: bills);
    expect(dashboard.monthlyCalls, hasLength(1));

    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Faturayı sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-bill-delete')));
    await tester.pumpAndSettle();

    expect(bills.deletedIds, ['bill-1']);
    expect(dashboard.monthlyCalls, hasLength(2));
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  MemoryTokenStorage storage,
  FakeDashboardService dashboard, {
  FakeExpenseService? expenses,
  FakeBillService? bills,
}) async {
  await tester.pumpWidget(
    SmartBudgetApp(
      authService: createAuthService(
        storage: storage,
        handler: (_) async => http.Response('{}', 500),
      ),
      dashboardService: dashboard,
      expenseService: expenses ?? FakeExpenseService(),
      incomeService: FakeIncomeService(),
      categoryService: FakeCategoryService(),
      budgetService: FakeBudgetService(),
      billService: bills ?? FakeBillService(),
      aiCategorizationService: FakeAiCategorizationService(),
      recurringRuleService: FakeRecurringRuleService(),
      tutorialStorage: storage,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _deleteExpense(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Gider kaydını sil'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-delete')));
  await tester.pumpAndSettle();
}
