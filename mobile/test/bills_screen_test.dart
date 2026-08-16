import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/screens/bills/bills_screen.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('renders bills, filters types and preserves null consumption', (
    tester,
  ) async {
    final service = FakeBillService(
      items: [
        sampleBill(
          id: 'electric',
          billType: BillType.electricity,
          amount: 1250.5,
          consumptionValue: null,
        ),
        sampleBill(id: 'water', billType: BillType.water),
        sampleBill(id: 'gas', billType: BillType.naturalGas),
      ],
      trend: sampleBillTrend(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elektrik'), findsWidgets);
    expect(find.text('Su'), findsWidgets);
    expect(find.text('Doğalgaz'), findsWidgets);
    expect(find.text('Tüketim bilgisi yok'), findsOneWidget);
    expect(find.text('₺1.250,50'), findsOneWidget);
    expect(find.text('16 Ağu 2026'), findsWidgets);

    await tester.tap(find.byKey(const Key('bill-filter-water')));
    await tester.pump();
    expect(find.byKey(const Key('bill-water')), findsOneWidget);
    expect(find.byKey(const Key('bill-electric')), findsNothing);
  });

  testWidgets(
    'trend shows six selected points and keeps null as missing data',
    (tester) async {
      final service = FakeBillService(trend: sampleBillTrend());
      await tester.pumpWidget(
        MaterialApp(
          home: BillsScreen(
            service: service,
            recurringRuleService: FakeRecurringRuleService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trend-electricity-2026-3')), findsOneWidget);
      expect(find.byKey(const Key('trend-electricity-2026-8')), findsOneWidget);
      expect(find.text('Tüketim verisi yok'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trend-type-water')));
      await tester.pump();
      expect(find.byKey(const Key('trend-water-2026-3')), findsOneWidget);
      expect(find.byKey(const Key('trend-electricity-2026-3')), findsNothing);
    },
  );

  testWidgets('trend shows empty state when selected type has no real data', (
    tester,
  ) async {
    final service = FakeBillService(
      trend: [
        ...emptyTrendFor(BillType.electricity),
        ...trendFor(BillType.water, amountMonth: 8),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Son 6 ay için fatura verisi yok.'), findsOneWidget);
    expect(find.byKey(const Key('trend-electricity-2026-3')), findsNothing);

    await tester.tap(find.byKey(const Key('trend-type-water')));
    await tester.pump();

    expect(find.text('Son 6 ay için fatura verisi yok.'), findsNothing);
    expect(find.byKey(const Key('trend-water-2026-3')), findsOneWidget);
    expect(find.byKey(const Key('trend-water-2026-8')), findsOneWidget);
  });

  testWidgets('trend keeps rows when selected type has a positive amount', (
    tester,
  ) async {
    final service = FakeBillService(
      trend: trendFor(BillType.electricity, amountMonth: 8),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Son 6 ay için fatura verisi yok.'), findsNothing);
    expect(find.byKey(const Key('trend-electricity-2026-3')), findsOneWidget);
    expect(find.byKey(const Key('trend-electricity-2026-8')), findsOneWidget);
  });

  testWidgets('trend treats non-null consumption as real data', (tester) async {
    final service = FakeBillService(
      trend: trendFor(BillType.electricity, consumptionMonth: 5),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Son 6 ay için fatura verisi yok.'), findsNothing);
    expect(find.byKey(const Key('trend-electricity-2026-3')), findsOneWidget);
    expect(find.byKey(const Key('trend-electricity-2026-8')), findsOneWidget);
    expect(find.text('12,5 kWh'), findsOneWidget);
  });

  testWidgets('trend error is isolated and retry only reloads trend', (
    tester,
  ) async {
    final service = FakeBillService(items: [sampleBill()]);
    service.getTrendHandler = () => throw Exception('failed');
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bill-bill-1')), findsOneWidget);
    expect(find.text('Trend verileri şu anda yüklenemedi.'), findsOneWidget);
    final listCalls = service.getAllCalls;
    service.getTrendHandler = () async => sampleBillTrend();
    await tester.tap(find.byKey(const Key('retry-bill-trend')));
    await tester.pumpAndSettle();
    expect(service.getAllCalls, listCalls);
    expect(service.getTrendCalls, 2);
  });

  testWidgets('delete asks confirmation, removes bill and refreshes trend', (
    tester,
  ) async {
    var financialChanges = 0;
    final service = FakeBillService(
      items: [sampleBill()],
      trend: sampleBillTrend(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
          onFinancialDataChanged: () => financialChanges++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Faturayı sil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu fatura kaydını silmek istediğinizden emin misiniz?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-bill-delete')));
    await tester.pumpAndSettle();
    expect(service.deletedIds, ['bill-1']);
    expect(service.getTrendCalls, 2);
    expect(financialChanges, 1);
    expect(find.byKey(const Key('bill-bill-1')), findsNothing);
  });

  testWidgets('successful create triggers one financial data refresh', (
    tester,
  ) async {
    var financialChanges = 0;
    final service = FakeBillService(trend: sampleBillTrend());
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
          onFinancialDataChanged: () => financialChanges++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-bill')));
    await tester.pumpAndSettle();
    await _completeBillForm(tester);

    expect(service.createCalls, 1);
    expect(service.getAllCalls, 2);
    expect(service.getTrendCalls, 2);
    expect(financialChanges, 1);
  });

  testWidgets(
    'recurring fixed-amount bill create still reports a financial change '
    '(rule may already be due and auto-realized by the backend)',
    (tester) async {
      var financialChanges = 0;
      final service = FakeBillService(trend: sampleBillTrend());
      final rules = FakeRecurringRuleService();
      await tester.pumpWidget(
        MaterialApp(
          home: BillsScreen(
            service: service,
            recurringRuleService: rules,
            onFinancialDataChanged: () => financialChanges++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-bill')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bill-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elektrik').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tutar'),
        '750',
      );
      await tester.tap(find.byKey(const Key('bill-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recurrence-monthly')));
      await tester.pump();
      await tester.tap(find.text('Faturayı Kaydet'));
      await tester.pumpAndSettle();

      expect(service.createCalls, 0);
      expect(rules.createCalls, 1);
      expect(financialChanges, 1);
      expect(service.getAllCalls, 2);
      expect(service.getTrendCalls, 2);
    },
  );

  testWidgets('failed create does not trigger financial data refresh', (
    tester,
  ) async {
    var financialChanges = 0;
    final service = FakeBillService();
    service.createHandler = (_) => throw Exception('failed');
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
          onFinancialDataChanged: () => financialChanges++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-bill')));
    await tester.pumpAndSettle();
    await _completeBillForm(tester);

    expect(find.text('Fatura kaydedilemedi. Tekrar deneyin.'), findsOneWidget);
    expect(financialChanges, 0);
  });

  testWidgets('failed delete does not trigger financial data refresh', (
    tester,
  ) async {
    var financialChanges = 0;
    final service = FakeBillService(items: [sampleBill()]);
    service.deleteHandler = (_) => throw Exception('failed');
    await tester.pumpWidget(
      MaterialApp(
        home: BillsScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
          onFinancialDataChanged: () => financialChanges++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Faturayı sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-bill-delete')));
    await tester.pumpAndSettle();

    expect(financialChanges, 0);
    expect(find.byKey(const Key('bill-bill-1')), findsOneWidget);
  });
}

Future<void> _completeBillForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bill-type')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Elektrik').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Tutar'), '100');
  await tester.tap(find.byKey(const Key('bill-date')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('16').last);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Faturayı Kaydet'));
  await tester.pumpAndSettle();
}

List<BillTrendPoint> emptyTrendFor(BillType type) => trendFor(type);

List<BillTrendPoint> trendFor(
  BillType type, {
  int? amountMonth,
  int? consumptionMonth,
}) => [
  for (var month = 3; month <= 8; month++)
    BillTrendPoint(
      year: 2026,
      month: month,
      billType: type,
      totalAmount: month == amountMonth ? 100 : 0,
      totalConsumption: month == consumptionMonth ? 12.5 : null,
      consumptionUnit: type.defaultUnit,
    ),
];
