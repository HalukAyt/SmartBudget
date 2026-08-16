import 'bill_models.dart' show BillType;
import 'transaction_models.dart';

enum RecurringRecordType {
  income('Income'),
  expense('Expense'),
  bill('Bill');

  const RecurringRecordType(this.apiValue);

  final String apiValue;

  static RecurringRecordType fromJson(Object? value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => throw FormatException('Unexpected RecordType value: $value'),
  );
}

/// Result of an "add" screen: either a real financial record was created
/// immediately, or a recurring rule (a plan, not a realized record) was
/// created instead. Dashboard/budget refresh must only follow [created].
enum AddRecordOutcome { created, recurringRuleCreated }

class CreateRecurringRuleRequest {
  const CreateRecurringRuleRequest({
    required this.recordType,
    required this.startDate,
    this.durationMonths,
    this.endDate,
    this.amount,
    this.description,
    this.categoryId,
    this.billType,
  });

  final RecurringRecordType recordType;
  final DateTime startDate;
  final int? durationMonths;
  final DateTime? endDate;
  final double? amount;
  final String? description;
  final String? categoryId;
  final BillType? billType;

  Map<String, Object?> toJson() => {
    'recordType': recordType.apiValue,
    'startDate': formatApiDate(startDate),
    'durationMonths': durationMonths,
    'endDate': endDate == null ? null : formatApiDate(endDate!),
    'amount': amount,
    'description': description,
    'categoryId': categoryId,
    'billType': billType?.apiValue,
  };
}

class RecurringRuleListItem {
  const RecurringRuleListItem({
    required this.id,
    required this.recordType,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.amount,
    required this.description,
    required this.category,
    required this.billType,
    required this.isRealizedThisMonth,
    required this.nextDueDate,
  });

  final String id;
  final RecurringRecordType recordType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double? amount;
  final String? description;
  final CategoryModel? category;
  final BillType? billType;
  final bool isRealizedThisMonth;

  /// Backend-computed next occurrence date; null once the rule has no more
  /// occurrences left (inactive, or past its EndDate). Authoritative — never
  /// recomputed on the client.
  final DateTime? nextDueDate;

  /// Month-level check mirroring the backend's due logic: is [month] within
  /// the rule's active [startDate, endDate] window (day-of-month ignored).
  bool isDueFor(DateTime month) {
    final start = DateTime(startDate.year, startDate.month);
    final end = DateTime(endDate.year, endDate.month);
    final target = DateTime(month.year, month.month);
    return isActive && !start.isAfter(target) && !end.isBefore(target);
  }

  String get displayTitle {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    return switch (recordType) {
      RecurringRecordType.income => 'Planlanan Gelir',
      RecurringRecordType.expense => category?.name ?? 'Planlanan Gider',
      RecurringRecordType.bill => billType?.label ?? 'Planlanan Fatura',
    };
  }

  factory RecurringRuleListItem.fromJson(Map<String, Object?> json) =>
      RecurringRuleListItem(
        id: _requiredString(json, 'id'),
        recordType: RecurringRecordType.fromJson(json['recordType']),
        startDate: _requiredDate(json, 'startDate'),
        endDate: _requiredDate(json, 'endDate'),
        isActive: _requiredBoolField(json, 'isActive'),
        amount: _nullableNumberField(json['amount']),
        description: _nullableStringField(json['description']),
        category: json['category'] == null
            ? null
            : CategoryModel.fromJson(readJsonObject(json['category'])),
        billType: json['billType'] == null
            ? null
            : BillType.fromJson(json['billType']),
        isRealizedThisMonth: _requiredBoolField(json, 'isRealizedThisMonth'),
        nextDueDate: json['nextDueDate'] == null
            ? null
            : _requiredDate(json, 'nextDueDate'),
      );
}

class RealizeRecurringRuleRequest {
  const RealizeRecurringRuleRequest({
    required this.year,
    required this.month,
    this.amount,
    this.consumptionValue,
  });

  final int year;
  final int month;
  final double? amount;
  final double? consumptionValue;

  Map<String, Object?> toJson() => {
    'year': year,
    'month': month,
    'amount': amount,
    'consumptionValue': consumptionValue,
  };
}

class RecurringRealizeResult {
  const RecurringRealizeResult({
    required this.recordType,
    required this.ruleId,
    required this.createdRecordId,
    required this.year,
    required this.month,
  });

  final RecurringRecordType recordType;
  final String ruleId;
  final String createdRecordId;
  final int year;
  final int month;

  factory RecurringRealizeResult.fromJson(Map<String, Object?> json) =>
      RecurringRealizeResult(
        recordType: RecurringRecordType.fromJson(json['recordType']),
        ruleId: _requiredString(json, 'ruleId'),
        createdRecordId: _requiredString(json, 'createdRecordId'),
        year: _requiredInt(json, 'year'),
        month: _requiredInt(json, 'month'),
      );
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected $key to be a string.');
}

bool _requiredBoolField(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Expected $key to be a boolean.');
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num && value.toInt() == value) return value.toInt();
  throw FormatException('Expected $key to be an integer.');
}

double? _nullableNumberField(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw const FormatException('Expected a nullable number.');
}

String? _nullableStringField(Object? value) {
  if (value == null || value is String) return value as String?;
  throw const FormatException('Expected a nullable string.');
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final date = DateTime.tryParse(value);
  if (date != null) return DateTime(date.year, date.month, date.day);
  throw FormatException('Expected $key to be a date.');
}
