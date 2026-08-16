import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/models/recurring_models.dart';

void main() {
  test('create payload contains only backend fields, no userId', () {
    final json = CreateRecurringRuleRequest(
      recordType: RecurringRecordType.expense,
      startDate: DateTime(2026, 8, 16),
      durationMonths: 12,
      amount: 20000,
      description: 'Kira',
      categoryId: 'category-rent',
    ).toJson();

    expect(json['recordType'], 'Expense');
    expect(json['startDate'], '2026-08-16');
    expect(json['durationMonths'], 12);
    expect(json['endDate'], isNull);
    expect(json['amount'], 20000);
    expect(json['categoryId'], 'category-rent');
    expect(json, isNot(contains('userId')));
  });

  test('bill rule payload carries billType and nullable amount', () {
    final json = CreateRecurringRuleRequest(
      recordType: RecurringRecordType.bill,
      startDate: DateTime(2026, 8, 16),
      durationMonths: 6,
      billType: BillType.electricity,
    ).toJson();

    expect(json['recordType'], 'Bill');
    expect(json['billType'], 'Electricity');
    expect(json['amount'], isNull);
  });

  test('custom end date payload omits durationMonths', () {
    final json = CreateRecurringRuleRequest(
      recordType: RecurringRecordType.income,
      startDate: DateTime(2026, 8, 16),
      endDate: DateTime(2027, 2, 1),
      amount: 45000,
    ).toJson();

    expect(json['durationMonths'], isNull);
    expect(json['endDate'], '2027-02-01');
  });

  test('rule list item parses backend fields and realized flag', () {
    final rule = RecurringRuleListItem.fromJson({
      'id': 'rule-1',
      'recordType': 'Income',
      'startDate': '2026-08-16',
      'endDate': '2027-01-16',
      'isActive': true,
      'amount': 45000,
      'description': 'Maaş',
      'category': null,
      'billType': null,
      'isRealizedThisMonth': false,
    });

    expect(rule.recordType, RecurringRecordType.income);
    expect(rule.amount, 45000);
    expect(rule.isRealizedThisMonth, isFalse);
    expect(rule.displayTitle, 'Maaş');
  });

  test('isDueFor checks month-level range regardless of day', () {
    final rule = RecurringRuleListItem.fromJson({
      'id': 'rule-1',
      'recordType': 'Expense',
      'startDate': '2026-08-20',
      'endDate': '2026-10-05',
      'isActive': true,
      'amount': 1000,
      'description': null,
      'category': {'id': 'category-rent', 'name': 'Kira'},
      'billType': null,
      'isRealizedThisMonth': false,
    });

    expect(rule.isDueFor(DateTime(2026, 8, 1)), isTrue);
    expect(rule.isDueFor(DateTime(2026, 9, 15)), isTrue);
    expect(rule.isDueFor(DateTime(2026, 10, 30)), isTrue);
    expect(rule.isDueFor(DateTime(2026, 11, 1)), isFalse);
    expect(rule.isDueFor(DateTime(2026, 7, 1)), isFalse);
  });

  test('inactive rule is never due', () {
    final rule = RecurringRuleListItem.fromJson({
      'id': 'rule-1',
      'recordType': 'Income',
      'startDate': '2026-01-01',
      'endDate': '2026-12-01',
      'isActive': false,
      'amount': 1000,
      'description': null,
      'category': null,
      'billType': null,
      'isRealizedThisMonth': false,
    });

    expect(rule.isDueFor(DateTime(2026, 6, 1)), isFalse);
  });

  test('realize payload includes optional amount and consumption', () {
    final json = const RealizeRecurringRuleRequest(
      year: 2026,
      month: 9,
      amount: 750,
      consumptionValue: 320,
    ).toJson();

    expect(json, {
      'year': 2026,
      'month': 9,
      'amount': 750,
      'consumptionValue': 320,
    });
  });

  test('realize result parses backend response', () {
    final result = RecurringRealizeResult.fromJson({
      'recordType': 'Bill',
      'ruleId': 'rule-1',
      'createdRecordId': 'bill-99',
      'year': 2026,
      'month': 9,
    });

    expect(result.recordType, RecurringRecordType.bill);
    expect(result.createdRecordId, 'bill-99');
  });
}
