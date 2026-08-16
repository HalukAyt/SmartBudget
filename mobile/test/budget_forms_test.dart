import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/config/app_theme.dart';
import 'package:smartbudget_mobile/models/budget_models.dart';
import 'package:smartbudget_mobile/screens/budgets/add_budget_screen.dart';
import 'package:smartbudget_mobile/screens/budgets/edit_budget_screen.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('create form requires category and positive limit', (
    tester,
  ) async {
    await _pumpCreate(tester);
    await tester.tap(find.text('Bütçeyi Kaydet'));
    await tester.pump();

    expect(find.text('Kategori seçmelisiniz.'), findsOneWidget);
    expect(find.text('Tutar zorunludur.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Bütçeyi Kaydet'));
    await tester.pump();
    expect(find.text('Tutar sıfırdan büyük olmalıdır.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '-1');
    await tester.tap(find.text('Bütçeyi Kaydet'));
    await tester.pump();
    expect(find.text('Tutar sıfırdan büyük olmalıdır.'), findsOneWidget);
  });

  testWidgets(
    'create sends selected category, month and year without user id',
    (tester) async {
      final budgets = FakeBudgetService();
      await _pumpCreate(tester, budgets: budgets);
      await _selectDropdown(tester, const Key('budget-category'), 'Market');
      await tester.enterText(find.byType(TextFormField), '2.500,50');
      await _selectDropdown(tester, const Key('budget-month'), 'Eylül');
      await _selectDropdown(tester, const Key('budget-year'), '2027');

      await tester.tap(find.text('Bütçeyi Kaydet'));
      await tester.pumpAndSettle();

      expect(budgets.createCalls, 1);
      expect(budgets.lastCreateRequest?.categoryId, 'category-market');
      expect(budgets.lastCreateRequest?.limitAmount, 2500.5);
      expect(budgets.lastCreateRequest?.month, 9);
      expect(budgets.lastCreateRequest?.year, 2027);
      expect(budgets.lastCreateRequest?.toJson(), isNot(contains('userId')));
    },
  );

  testWidgets('duplicate 409 displays a friendly message', (tester) async {
    final budgets = FakeBudgetService()
      ..createHandler = (_) async => throw const ApiException(
        ApiErrorType.conflict,
        'A budget already exists.',
        statusCode: 409,
      );
    await _pumpCreate(tester, budgets: budgets);
    await _selectDropdown(tester, const Key('budget-category'), 'Market');
    await tester.enterText(find.byType(TextFormField), '2000');
    await tester.tap(find.text('Bütçeyi Kaydet'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bu kategori için seçilen dönemde zaten bir bütçe bulunuyor.'),
      findsOneWidget,
    );
  });

  testWidgets('create double submit is blocked', (tester) async {
    final completer = Completer<BudgetListItem>();
    final budgets = FakeBudgetService()
      ..createHandler = (_) => completer.future;
    await _pumpCreate(tester, budgets: budgets);
    await _selectDropdown(tester, const Key('budget-category'), 'Market');
    await tester.enterText(find.byType(TextFormField), '2000');

    await tester.tap(find.text('Bütçeyi Kaydet'));
    await tester.tap(find.text('Bütçeyi Kaydet'), warnIfMissed: false);
    await tester.pump();
    expect(budgets.createCalls, 1);

    completer.complete(sampleBudget());
    await tester.pumpAndSettle();
  });

  testWidgets('edit shows immutable fields and only limit is editable', (
    tester,
  ) async {
    await _pumpEdit(tester);

    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Ay'), findsOneWidget);
    expect(find.text('Ağustos'), findsOneWidget);
    expect(find.text('Yıl'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Bütçe Limiti'), findsOneWidget);
  });

  testWidgets('update submits only new limit amount', (tester) async {
    final budgets = FakeBudgetService(items: [sampleBudget()]);
    await _pumpEdit(tester, budgets: budgets);
    await tester.enterText(find.byType(TextFormField), '3.500,75');
    await tester.tap(find.text('Limiti Güncelle'));
    await tester.pumpAndSettle();

    expect(budgets.updateCalls, 1);
    expect(budgets.lastUpdateId, 'budget-1');
    expect(budgets.lastUpdateRequest?.toJson(), {'limitAmount': 3500.75});
    expect(budgets.lastUpdateRequest?.toJson(), isNot(contains('categoryId')));
    expect(budgets.lastUpdateRequest?.toJson(), isNot(contains('month')));
    expect(budgets.lastUpdateRequest?.toJson(), isNot(contains('year')));
    expect(budgets.lastUpdateRequest?.toJson(), isNot(contains('userId')));
  });

  testWidgets('update 404 shows ownership-safe message', (tester) async {
    final budgets = FakeBudgetService()
      ..updateHandler = (_, _) async => throw const ApiException(
        ApiErrorType.notFound,
        'Not found',
        statusCode: 404,
      );
    await _pumpEdit(tester, budgets: budgets);
    await tester.enterText(find.byType(TextFormField), '3000');
    await tester.tap(find.text('Limiti Güncelle'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bütçe kaydı bulunamadı veya artık mevcut değil.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpCreate(WidgetTester tester, {FakeBudgetService? budgets}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AddBudgetScreen(
          categories: sampleCategories,
          budgetService: budgets ?? FakeBudgetService(),
          initialYear: 2026,
          initialMonth: 8,
        ),
      ),
    );

Future<void> _pumpEdit(WidgetTester tester, {FakeBudgetService? budgets}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EditBudgetScreen(
          budget: sampleBudget(),
          budgetService: budgets ?? FakeBudgetService(items: [sampleBudget()]),
        ),
      ),
    );

Future<void> _selectDropdown(WidgetTester tester, Key key, String value) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}
