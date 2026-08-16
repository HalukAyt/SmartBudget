import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';

void main() {
  test('bill types parse safely and expose API values', () {
    expect(BillType.fromJson('Electricity'), BillType.electricity);
    expect(BillType.fromJson('Water'), BillType.water);
    expect(BillType.fromJson('NaturalGas'), BillType.naturalGas);
    expect(BillType.fromJson('Internet'), BillType.unknown);
  });

  test(
    'create payload contains only backend fields and nullable consumption',
    () {
      final json = CreateBillRequest(
        billType: BillType.electricity,
        amount: 450.5,
        consumptionValue: null,
        billingDate: DateTime(2026, 8, 16),
      ).toJson();

      expect(json, {
        'billType': 'Electricity',
        'amount': 450.5,
        'consumptionValue': null,
        'billingDate': '2026-08-16',
      });
      expect(json, isNot(contains('userId')));
      expect(json, isNot(contains('consumptionUnit')));
      expect(json, isNot(contains('paymentStatus')));
      expect(json, isNot(contains('prediction')));
    },
  );

  test('bill and trend preserve backend values and null consumption', () {
    final bill = BillListItem.fromJson({
      'id': 'bill-1',
      'billType': 'Water',
      'amount': 123.45,
      'consumptionValue': null,
      'consumptionUnit': 'm³',
      'billingDate': '2026-08-16',
      'createdAt': '2026-08-16T12:00:00Z',
    });
    final point = BillTrendPoint.fromJson({
      'year': 2026,
      'month': 8,
      'billType': 'NaturalGas',
      'totalAmount': 987.65,
      'totalConsumption': null,
      'consumptionUnit': 'm³',
    });
    expect(bill.billType, BillType.water);
    expect(bill.consumptionValue, isNull);
    expect(point.billType, BillType.naturalGas);
    expect(point.totalAmount, 987.65);
    expect(point.totalConsumption, isNull);
  });
}
