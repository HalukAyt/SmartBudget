import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/config/app_theme.dart';
import 'package:smartbudget_mobile/models/budget_models.dart';
import 'package:smartbudget_mobile/models/dashboard_models.dart';
import 'package:smartbudget_mobile/screens/budgets/budgets_screen.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('shows loading then selected-period budget list', (tester) async {
    final completer = Completer<List<BudgetListItem>>();
    final budgets = FakeBudgetService()..getAllHandler = () => completer.future;
    await _pumpBudgets(tester, budgets: budgets);
    expect(find.text('Bütçeler yükleniyor…'), findsOneWidget);

    completer.complete([sampleBudget()]);
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Ağustos 2026'), findsOneWidget);
  });

  testWidgets('error retries and empty selected period is successful', (
    tester,
  ) async {
    var attempt = 0;
    final budgets = FakeBudgetService()
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
    await _pumpBudgets(tester, budgets: budgets);
    await tester.pumpAndSettle();
    expect(find.text('Bağlantı kurulamadı.'), findsOneWidget);

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu dönem için henüz bütçe oluşturulmamış.'),
      findsOneWidget,
    );
  });

  testWidgets('period selector filters presentation without another API call', (
    tester,
  ) async {
    final budgets = FakeBudgetService(
      items: [
        sampleBudget(id: 'august', month: 8, categoryName: 'Market'),
        sampleBudget(id: 'july', month: 7, categoryId: 'category-transport'),
      ],
    );
    await _pumpBudgets(tester, budgets: budgets);
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Ulaşım'), findsNothing);

    await tester.tap(find.byKey(const Key('period-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('budget-period-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temmuz').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-budget-period')));
    await tester.pumpAndSettle();

    expect(find.text('Market'), findsNothing);
    expect(find.text('Ulaşım'), findsOneWidget);
    expect(budgets.getAllCalls, 1);
  });

  testWidgets(
    'status labels and backend percentage render without recalculation',
    (tester) async {
      final budgets = FakeBudgetService(
        items: [
          sampleBudget(
            id: 'normal',
            categoryName: 'Market',
            usagePercent: 50,
            alertStatus: BudgetAlertStatus.normal,
          ),
          sampleBudget(
            id: 'warning',
            categoryId: 'category-transport',
            usagePercent: 85,
            alertStatus: BudgetAlertStatus.warning,
          ),
          sampleBudget(
            id: 'exceeded',
            categoryName: 'Fatura',
            usagePercent: 135,
            alertStatus: BudgetAlertStatus.exceeded,
          ),
          sampleBudget(
            id: 'unknown',
            categoryName: 'Diğer',
            usagePercent: 10,
            alertStatus: BudgetAlertStatus.unknown,
          ),
        ],
      );
      await _pumpBudgets(tester, budgets: budgets);
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Limite Yakın'), findsOneWidget);
      expect(find.text('Limit Aşıldı'), findsOneWidget);
      expect(find.text('%135'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('budget-progress-exceeded')),
      );
      expect(progress.value, 1.0);
      await tester.scrollUntilVisible(
        find.text('Durum Bilinmiyor'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Durum Bilinmiyor'), findsOneWidget);
    },
  );

  testWidgets('pull to refresh reloads budgets but not cached categories', (
    tester,
  ) async {
    final budgets = FakeBudgetService(items: [sampleBudget()]);
    final categories = FakeCategoryService();
    await _pumpBudgets(tester, budgets: budgets, categories: categories);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('budgets-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    expect(budgets.getAllCalls, 2);
    expect(categories.getAllCalls, 1);
  });

  testWidgets('delete confirmation removes budget and reveals empty state', (
    tester,
  ) async {
    final budgets = FakeBudgetService(items: [sampleBudget()]);
    await _pumpBudgets(tester, budgets: budgets);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bütçeyi sil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu bütçe kaydını silmek istediğinizden emin misiniz?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-budget-delete')));
    await tester.pumpAndSettle();

    expect(budgets.deletedIds, ['budget-1']);
    expect(
      find.text('Bu dönem için henüz bütçe oluşturulmamış.'),
      findsOneWidget,
    );
  });

  testWidgets('delete 404 displays ownership-safe message', (tester) async {
    final budgets = FakeBudgetService(items: [sampleBudget()])
      ..deleteHandler = (_) async => throw const ApiException(
        ApiErrorType.notFound,
        'Not found',
        statusCode: 404,
      );
    await _pumpBudgets(tester, budgets: budgets);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bütçeyi sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-budget-delete')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bütçe kaydı bulunamadı veya artık mevcut değil.'),
      findsOneWidget,
    );
  });

  testWidgets('create success refreshes list for selected period', (
    tester,
  ) async {
    final budgets = FakeBudgetService();
    await _pumpBudgets(tester, budgets: budgets);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-budget')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('budget-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market').last);
    await tester.enterText(find.byType(TextFormField), '2000');
    await tester.tap(find.text('Bütçeyi Kaydet'));
    await tester.pumpAndSettle();

    expect(budgets.createCalls, 1);
    expect(budgets.getAllCalls, 2);
    expect(find.text('Market'), findsOneWidget);
  });

  testWidgets(
    'update keeps backend usage percentage instead of calculating it',
    (tester) async {
      final budgets = FakeBudgetService(items: [sampleBudget()]);
      await _pumpBudgets(tester, budgets: budgets);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Düzenle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '4000');
      await tester.tap(find.text('Limiti Güncelle'));
      await tester.pumpAndSettle();

      expect(budgets.updateCalls, 1);
      expect(budgets.getAllCalls, 2);
      expect(find.text('%135'), findsOneWidget);
      expect(find.text('₺4.000,00'), findsOneWidget);
    },
  );
}

Future<void> _pumpBudgets(
  WidgetTester tester, {
  FakeBudgetService? budgets,
  FakeCategoryService? categories,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: BudgetsScreen(
      budgetService: budgets ?? FakeBudgetService(),
      categoryService: categories ?? FakeCategoryService(),
      initialYear: 2026,
      initialMonth: 8,
    ),
  ),
);
