import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/screens/bills/add_bill_screen.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('requires type, positive amount and date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddBillScreen(
          service: FakeBillService(),
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.tap(find.text('Faturayı Kaydet'));
    await tester.pump();
    expect(find.text('Fatura türü seçmelisiniz.'), findsOneWidget);
    expect(find.text('Tutar zorunludur.'), findsOneWidget);
    expect(find.text('Fatura tarihi zorunludur.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Tutar'), '0');
    await tester.tap(find.text('Faturayı Kaydet'));
    await tester.pump();
    expect(find.text('Tutar sıfırdan büyük olmalıdır.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Tutar'), '-1');
    await tester.tap(find.text('Faturayı Kaydet'));
    await tester.pump();
    expect(find.text('Tutar sıfırdan büyük olmalıdır.'), findsOneWidget);
  });

  testWidgets('optional consumption validates only when supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddBillScreen(
          service: FakeBillService(),
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    final consumption = find.widgetWithText(
      TextFormField,
      'Tüketim Miktarı (opsiyonel)',
    );
    await tester.enterText(consumption, '0');
    await tester.tap(find.text('Faturayı Kaydet'));
    await tester.pump();
    expect(
      find.text('Tüketim miktarı sıfırdan büyük olmalıdır.'),
      findsOneWidget,
    );
    await tester.enterText(consumption, '-2');
    await tester.tap(find.text('Faturayı Kaydet'));
    await tester.pump();
    expect(
      find.text('Tüketim miktarı sıfırdan büyük olmalıdır.'),
      findsOneWidget,
    );
  });

  testWidgets('selected type changes unit helper and sends backend enum', (
    tester,
  ) async {
    final service = FakeBillService();
    await tester.pumpWidget(
      MaterialApp(
        home: AddBillScreen(
          service: service,
          recurringRuleService: FakeRecurringRuleService(),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('bill-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elektrik').last);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Tüketim Miktarı (kWh)'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tutar'),
      '100,50',
    );
    await tester.tap(find.byKey(const Key('bill-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faturayı Kaydet'));
    await tester.pumpAndSettle();
    expect(service.createCalls, 1);
    expect(service.lastCreateRequest!.billType, BillType.electricity);
    expect(service.lastCreateRequest!.consumptionValue, isNull);
    final json = service.lastCreateRequest!.toJson();
    expect(json, isNot(contains('userId')));
    expect(json, isNot(contains('consumptionUnit')));
  });
}
