import 'transaction_models.dart';

enum BillType {
  electricity('Electricity', 'Elektrik', 'kWh'),
  water('Water', 'Su', 'm³'),
  naturalGas('NaturalGas', 'Doğalgaz', 'm³'),
  unknown('', 'Bilinmeyen Fatura', '');

  const BillType(this.apiValue, this.label, this.defaultUnit);

  final String apiValue;
  final String label;
  final String defaultUnit;

  static BillType fromJson(Object? value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => BillType.unknown,
  );
}

class CreateBillRequest {
  const CreateBillRequest({
    required this.billType,
    required this.amount,
    required this.consumptionValue,
    required this.billingDate,
  });

  final BillType billType;
  final double amount;
  final double? consumptionValue;
  final DateTime billingDate;

  Map<String, Object?> toJson() => {
    'billType': billType.apiValue,
    'amount': amount,
    'consumptionValue': consumptionValue,
    'billingDate': formatApiDate(billingDate),
  };
}

class BillListItem {
  const BillListItem({
    required this.id,
    required this.billType,
    required this.amount,
    required this.consumptionValue,
    required this.consumptionUnit,
    required this.billingDate,
    required this.createdAt,
  });

  final String id;
  final BillType billType;
  final double amount;
  final double? consumptionValue;
  final String consumptionUnit;
  final DateTime billingDate;
  final DateTime createdAt;

  factory BillListItem.fromJson(Map<String, Object?> json) => BillListItem(
    id: _string(json, 'id'),
    billType: BillType.fromJson(json['billType']),
    amount: _number(json, 'amount'),
    consumptionValue: _nullableNumber(json['consumptionValue']),
    consumptionUnit: _string(json, 'consumptionUnit'),
    billingDate: _date(json, 'billingDate'),
    createdAt: _dateTime(json, 'createdAt'),
  );
}

class BillTrendPoint {
  const BillTrendPoint({
    required this.year,
    required this.month,
    required this.billType,
    required this.totalAmount,
    required this.totalConsumption,
    required this.consumptionUnit,
  });

  final int year;
  final int month;
  final BillType billType;
  final double totalAmount;
  final double? totalConsumption;
  final String consumptionUnit;

  factory BillTrendPoint.fromJson(Map<String, Object?> json) => BillTrendPoint(
    year: _integer(json, 'year'),
    month: _integer(json, 'month'),
    billType: BillType.fromJson(json['billType']),
    totalAmount: _number(json, 'totalAmount'),
    totalConsumption: _nullableNumber(json['totalConsumption']),
    consumptionUnit: _string(json, 'consumptionUnit'),
  );
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected $key to be a string.');
}

double _number(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Expected $key to be a number.');
}

double? _nullableNumber(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw const FormatException('Expected a nullable number.');
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num && value.toInt() == value) return value.toInt();
  throw FormatException('Expected $key to be an integer.');
}

DateTime _date(Map<String, Object?> json, String key) {
  final parsed = DateTime.tryParse(_string(json, key));
  if (parsed == null) throw FormatException('Expected $key to be a date.');
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _dateTime(Map<String, Object?> json, String key) {
  final parsed = DateTime.tryParse(_string(json, key));
  if (parsed != null) return parsed;
  throw FormatException('Expected $key to be a date-time.');
}
