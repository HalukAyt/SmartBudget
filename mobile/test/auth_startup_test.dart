import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smartbudget_mobile/app.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('missing token opens login screen', (tester) async {
    final storage = MemoryTokenStorage();
    final service = createAuthService(
      storage: storage,
      handler: (_) async => http.Response('', 500),
    );

    await tester.pumpWidget(
      SmartBudgetApp(
        authService: service,
        dashboardService: FakeDashboardService(),
        expenseService: FakeExpenseService(),
        incomeService: FakeIncomeService(),
        categoryService: FakeCategoryService(),
        budgetService: FakeBudgetService(),
        billService: FakeBillService(),
        aiCategorizationService: FakeAiCategorizationService(),
        recurringRuleService: FakeRecurringRuleService(),
        tutorialStorage: storage,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsNothing);
  });

  testWidgets('stored token opens authenticated shell', (tester) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'user@example.com';
    final service = createAuthService(
      storage: storage,
      handler: (_) async => http.Response('', 500),
    );

    await tester.pumpWidget(
      SmartBudgetApp(
        authService: service,
        dashboardService: FakeDashboardService(),
        expenseService: FakeExpenseService(),
        incomeService: FakeIncomeService(),
        categoryService: FakeCategoryService(),
        budgetService: FakeBudgetService(),
        billService: FakeBillService(),
        aiCategorizationService: FakeAiCategorizationService(),
        recurringRuleService: FakeRecurringRuleService(),
        tutorialStorage: storage,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finansal durumun'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
