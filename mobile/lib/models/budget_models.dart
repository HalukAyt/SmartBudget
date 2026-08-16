import 'dashboard_models.dart';
import 'transaction_models.dart';

class CreateBudgetRequest {
  const CreateBudgetRequest({
    required this.categoryId,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  final String categoryId;
  final double limitAmount;
  final int month;
  final int year;

  Map<String, Object?> toJson() => {
    'categoryId': categoryId,
    'limitAmount': limitAmount,
    'month': month,
    'year': year,
  };
}

class UpdateBudgetRequest {
  const UpdateBudgetRequest({required this.limitAmount});

  final double limitAmount;

  Map<String, Object?> toJson() => {'limitAmount': limitAmount};
}

class BudgetListItem {
  const BudgetListItem({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
    required this.spentAmount,
    required this.usagePercent,
    required this.alertStatus,
    required this.createdAt,
  });

  final String id;
  final CategoryModel category;
  final double limitAmount;
  final int month;
  final int year;
  final double spentAmount;
  final double usagePercent;
  final BudgetAlertStatus alertStatus;
  final DateTime createdAt;

  factory BudgetListItem.fromJson(Map<String, Object?> json) => BudgetListItem(
    id: _requiredString(json, 'id'),
    category: CategoryModel.fromJson(_requiredMap(json, 'category')),
    limitAmount: _requiredNumber(json, 'limitAmount'),
    month: _requiredInt(json, 'month'),
    year: _requiredInt(json, 'year'),
    spentAmount: _requiredNumber(json, 'spentAmount'),
    usagePercent: _requiredNumber(json, 'usagePercent'),
    alertStatus: BudgetAlertStatus.fromJson(json['alertStatus']),
    createdAt: _requiredDateTime(json, 'createdAt'),
  );
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected $key to be an object.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected $key to be a string.');
}

double _requiredNumber(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Expected $key to be a number.');
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Expected $key to be an integer.');
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final result = DateTime.tryParse(value);
  if (result != null) return result;
  throw FormatException('Expected $key to be a date-time.');
}
