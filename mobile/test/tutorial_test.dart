import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:smartbudget_mobile/app.dart';
import 'package:smartbudget_mobile/services/auth_service.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets(
    'successful first login opens tutorial after authenticated shell',
    (tester) async {
      final storage = MemoryTokenStorage();
      final authService = _authService(storage);
      await _pumpApp(tester, authService, storage);

      expect(find.byKey(const Key('tutorial-dialog')), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new.user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Sayfa'), findsWidgets);
      expect(_selectedTab(tester), 0);
      expect(find.byKey(const Key('tutorial-dialog')), findsOneWidget);
      expect(find.text("SmartBudget AI'ye Hoş Geldiniz"), findsOneWidget);
    },
  );

  testWidgets('seen user does not open tutorial automatically', (tester) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'seen@example.com';
    await storage.markTutorialSeen('seen@example.com');

    await _pumpApp(tester, _authService(storage), storage);

    expect(find.byKey(const Key('tutorial-dialog')), findsNothing);
    expect(find.text('Finansal durumun'), findsOneWidget);
  });

  testWidgets('skip closes tutorial and stores seen state', (tester) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'skip@example.com';
    await _pumpApp(tester, _authService(storage), storage);

    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutorial-dialog')), findsNothing);
    expect(await storage.hasSeenTutorial(' SKIP@example.com '), isTrue);
  });

  testWidgets('next back and final start complete the tutorial', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'finish@example.com';
    await _pumpApp(tester, _authService(storage), storage);

    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.byKey(const Key('tutorial-back')), findsNothing);
    await _next(tester);
    expect(find.text('2 / 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial-back')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 6'), findsOneWidget);

    for (var index = 0; index < 5; index++) {
      await _next(tester);
    }
    expect(find.text('6 / 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial-start')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutorial-dialog')), findsNothing);
    expect(await storage.hasSeenTutorial('finish@example.com'), isTrue);
  });

  testWidgets(
    'walkthrough changes real tabs without writes or automatic AI calls',
    (tester) async {
      final storage = MemoryTokenStorage()
        ..token = 'jwt-token'
        ..email = 'walkthrough@example.com';
      final dashboardService = FakeDashboardService();
      final expenseService = FakeExpenseService();
      final incomeService = FakeIncomeService();
      final budgetService = FakeBudgetService();
      final billService = FakeBillService();
      final aiService = FakeAiCategorizationService();
      await _pumpApp(
        tester,
        _authService(storage),
        storage,
        dashboardService: dashboardService,
        expenseService: expenseService,
        incomeService: incomeService,
        budgetService: budgetService,
        billService: billService,
        aiService: aiService,
      );

      expect(_selectedTab(tester), 0);
      expect(find.text('Finansal durumun'), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-target-dashboard-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tutorial-highlight-step-0')),
        findsOneWidget,
      );

      await _next(tester);
      expect(_selectedTab(tester), 1);
      expect(find.text('Gelir ve Giderlerinizi Ekleyin'), findsOneWidget);
      expect(find.byKey(const Key('add-transaction')), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-highlight-step-1')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('add-transaction')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.text('Yeni İşlem'), findsNothing);

      await _next(tester);
      expect(_selectedTab(tester), 1);
      expect(find.text('AI ile Kategori Önerisi'), findsOneWidget);
      expect(find.text('Gider Ekle'), findsOneWidget);
      expect(find.byKey(const Key('add-transaction')), findsNothing);
      expect(find.byKey(const Key('ai-category-button')), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-highlight-step-2')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('tutorial-back')));
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 1);
      expect(find.text('Gelir ve Giderlerinizi Ekleyin'), findsOneWidget);
      expect(find.byKey(const Key('add-transaction')), findsOneWidget);
      expect(find.byKey(const Key('ai-category-button')), findsNothing);
      expect(
        find.byKey(const Key('tutorial-highlight-step-1')),
        findsOneWidget,
      );

      await _next(tester);
      expect(find.byKey(const Key('ai-category-button')), findsOneWidget);

      await _next(tester);
      expect(_selectedTab(tester), 2);
      expect(find.text('Bütçenizi Kontrol Edin'), findsOneWidget);
      expect(find.byKey(const Key('ai-category-button')), findsNothing);
      expect(find.byKey(const Key('add-budget')), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-highlight-step-3')),
        findsOneWidget,
      );

      await _next(tester);
      expect(_selectedTab(tester), 3);
      expect(find.text('Faturalarınızı Takip Edin'), findsOneWidget);
      expect(find.byKey(const Key('add-bill')), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-highlight-step-4')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('tutorial-back')));
      await tester.pumpAndSettle();
      expect(_selectedTab(tester), 2);
      expect(find.text('Bütçenizi Kontrol Edin'), findsOneWidget);

      await _next(tester);
      await _next(tester);
      expect(_selectedTab(tester), 0);
      expect(find.text('AI Aylık Analizi'), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-target-dashboard-ai')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tutorial-highlight-step-5')),
        findsOneWidget,
      );

      expect(expenseService.createCalls, 0);
      expect(incomeService.createCalls, 0);
      expect(budgetService.createCalls, 0);
      expect(budgetService.updateCalls, 0);
      expect(billService.createCalls, 0);
      expect(aiService.calls, 0);
      expect(dashboardService.analysisCalls, isEmpty);
      expect(expenseService.deletedIds, isEmpty);
      expect(incomeService.deletedIds, isEmpty);
      expect(budgetService.deletedIds, isEmpty);
      expect(billService.deletedIds, isEmpty);
    },
  );

  testWidgets('skipping AI category step closes tutorial expense preview', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'skip-ai-preview@example.com';
    final expenseService = FakeExpenseService();
    final aiService = FakeAiCategorizationService();
    await _pumpApp(
      tester,
      _authService(storage),
      storage,
      expenseService: expenseService,
      aiService: aiService,
    );

    await _next(tester);
    await _next(tester);
    expect(find.byKey(const Key('ai-category-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutorial-dialog')), findsNothing);
    expect(find.byKey(const Key('ai-category-button')), findsNothing);
    expect(find.byKey(const Key('add-transaction')), findsOneWidget);
    expect(expenseService.createCalls, 0);
    expect(aiService.calls, 0);
  });

  testWidgets('coach mark card is compact relative to the screen', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'compact@example.com';
    await _pumpApp(tester, _authService(storage), storage);

    final overlayHeight = tester
        .getSize(find.byKey(const Key('tutorial-dialog')))
        .height;
    final cardHeight = tester
        .getSize(find.byKey(const Key('tutorial-card')))
        .height;
    expect(cardHeight, lessThan(overlayHeight * 0.5));
  });

  testWidgets('help button manually reopens tutorial for a seen user', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'manual@example.com';
    await storage.markTutorialSeen('manual@example.com');
    await _pumpApp(tester, _authService(storage), storage);

    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pump();
    expect(_selectedTab(tester), 4);
    await tester.tap(find.byTooltip('Yardım'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutorial-dialog')), findsOneWidget);
    expect(_selectedTab(tester), 0);
    expect(await storage.hasSeenTutorial('manual@example.com'), isTrue);
  });

  testWidgets('active walkthrough cannot be stacked from help button', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'single-overlay@example.com';
    await _pumpApp(tester, _authService(storage), storage);

    expect(find.byKey(const Key('tutorial-dialog')), findsOneWidget);
    await tester.tap(find.byTooltip('Yardım'), warnIfMissed: false);
    await tester.pump();
    expect(find.byKey(const Key('tutorial-dialog')), findsOneWidget);
  });

  testWidgets('tutorial state survives same-user login and is user-specific', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'first@example.com';
    final authService = _authService(storage);
    await _pumpApp(tester, authService, storage);
    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await tester.pumpAndSettle();

    await authService.logout();
    await tester.pumpAndSettle();
    await authService.login(email: 'first@example.com', password: 'password');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial-dialog')), findsNothing);

    await authService.logout();
    await tester.pumpAndSettle();
    await authService.login(email: 'second@example.com', password: 'password');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial-dialog')), findsOneWidget);
  });

  testWidgets('help button is accessible on all authenticated tabs', (
    tester,
  ) async {
    final storage = MemoryTokenStorage()
      ..token = 'jwt-token'
      ..email = 'tabs@example.com';
    await storage.markTutorialSeen('tabs@example.com');
    await _pumpApp(tester, _authService(storage), storage);

    for (var index = 0; index < 5; index++) {
      if (index > 0) {
        await tester.tap(find.byType(NavigationDestination).at(index));
        await tester.pump();
      }
      expect(find.byTooltip('Yardım'), findsOneWidget);
    }
  });
}

AuthService _authService(MemoryTokenStorage storage) => createAuthService(
  storage: storage,
  handler: (request) async {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final email = body['email'] as String;
    return http.Response(
      jsonEncode({
        'accessToken': 'jwt-token',
        'userId': 'd2719e6d-a20b-4a16-a3be-1036c5c3500f',
        'email': email,
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  },
);

Future<void> _pumpApp(
  WidgetTester tester,
  AuthService authService,
  MemoryTokenStorage storage, {
  FakeDashboardService? dashboardService,
  FakeExpenseService? expenseService,
  FakeIncomeService? incomeService,
  FakeBudgetService? budgetService,
  FakeBillService? billService,
  FakeAiCategorizationService? aiService,
}) async {
  await tester.pumpWidget(
    SmartBudgetApp(
      authService: authService,
      dashboardService: dashboardService ?? FakeDashboardService(),
      expenseService: expenseService ?? FakeExpenseService(),
      incomeService: incomeService ?? FakeIncomeService(),
      categoryService: FakeCategoryService(),
      budgetService: budgetService ?? FakeBudgetService(),
      billService: billService ?? FakeBillService(),
      aiCategorizationService: aiService ?? FakeAiCategorizationService(),
      recurringRuleService: FakeRecurringRuleService(),
      tutorialStorage: storage,
    ),
  );
  await tester.pumpAndSettle();
}

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tutorial-next')));
  await tester.pumpAndSettle();
}
