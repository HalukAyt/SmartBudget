import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/screens/bills/bills_view_model.dart';
import 'package:smartbudget_mobile/services/api_client.dart';

import 'helpers/fakes.dart';

void main() {
  test('loads independently, filters bills and sorts selected trend', () async {
    final service = FakeBillService(
      items: [
        sampleBill(id: 'e', billType: BillType.electricity),
        sampleBill(id: 'w', billType: BillType.water),
        sampleBill(id: 'g', billType: BillType.naturalGas),
      ],
      trend: sampleBillTrend().reversed.toList(),
    );
    final model = BillsViewModel(
      service: service,
      recurringRuleService: FakeRecurringRuleService(),
    );
    await model.loadInitial();
    expect(service.getAllCalls, 1);
    expect(service.getTrendCalls, 1);
    model.selectFilter(BillFilter.water);
    expect(model.visibleBills.map((item) => item.id), ['w']);
    model.selectTrendType(BillType.naturalGas);
    expect(model.visibleTrend, hasLength(6));
    expect(model.visibleTrend.first.month, 3);
    expect(model.visibleTrend.last.month, 8);
  });

  test(
    'trend failure does not break bill list and retry only reloads trend',
    () async {
      final service = FakeBillService(items: [sampleBill()]);
      service.getTrendHandler = () => throw Exception('trend');
      final model = BillsViewModel(
        service: service,
        recurringRuleService: FakeRecurringRuleService(),
      );
      await model.loadInitial();
      expect(model.bills, hasLength(1));
      expect(model.listError, isNull);
      expect(model.trendError, isNotNull);
      final listCalls = service.getAllCalls;
      service.getTrendHandler = () async => sampleBillTrend();
      await model.loadTrend();
      expect(service.getAllCalls, listCalls);
      expect(model.trend, hasLength(18));
    },
  );

  test('delete removes bill and refreshes backend trend', () async {
    final bill = sampleBill();
    final service = FakeBillService(items: [bill], trend: sampleBillTrend());
    final model = BillsViewModel(
      service: service,
      recurringRuleService: FakeRecurringRuleService(),
    );
    await model.loadInitial();
    final initialTrendCalls = service.getTrendCalls;
    expect(await model.deleteBill(bill), isNull);
    expect(model.bills, isEmpty);
    expect(service.deletedIds, ['bill-1']);
    expect(service.getTrendCalls, initialTrendCalls + 1);
  });

  test('delete 404 returns safe message and reloads list and trend', () async {
    final bill = sampleBill();
    final service = FakeBillService(items: [bill]);
    service.deleteHandler = (_) async =>
        throw const ApiException(ApiErrorType.notFound, 'raw', statusCode: 404);
    final model = BillsViewModel(
      service: service,
      recurringRuleService: FakeRecurringRuleService(),
    );
    await model.loadInitial();
    final message = await model.deleteBill(bill);
    expect(message, 'Fatura kaydı bulunamadı veya artık mevcut değil.');
    expect(service.getAllCalls, 2);
    expect(service.getTrendCalls, 2);
  });
}
