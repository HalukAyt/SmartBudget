class CategoryModel {
  const CategoryModel({required this.id, required this.name});

  final String id;
  final String name;

  factory CategoryModel.fromJson(Map<String, Object?> json) => CategoryModel(
    id: _requiredString(json, 'id'),
    name: _requiredString(json, 'name'),
  );
}

class CreateExpenseRequest {
  const CreateExpenseRequest({
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.date,
    required this.isAiCategorized,
  });

  final double amount;
  final String description;
  final String categoryId;
  final DateTime date;
  final bool isAiCategorized;

  Map<String, Object?> toJson() => {
    'amount': amount,
    'description': description,
    'categoryId': categoryId,
    'date': formatApiDate(date),
    'isAiCategorized': isAiCategorized,
  };
}

class ExpenseListItem {
  const ExpenseListItem({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.createdAt,
    required this.isAiCategorized,
  });

  final String id;
  final double amount;
  final String description;
  final CategoryModel category;
  final DateTime date;
  final DateTime createdAt;
  final bool isAiCategorized;

  factory ExpenseListItem.fromJson(Map<String, Object?> json) =>
      ExpenseListItem(
        id: _requiredString(json, 'id'),
        amount: _requiredNumber(json, 'amount'),
        description: _requiredString(json, 'description'),
        category: CategoryModel.fromJson(_requiredMap(json, 'category')),
        date: _requiredDate(json, 'date'),
        createdAt: _requiredDateTime(json, 'createdAt'),
        isAiCategorized: _requiredBool(json, 'isAiCategorized'),
      );
}

class CreateIncomeRequest {
  const CreateIncomeRequest({
    required this.amount,
    required this.description,
    required this.date,
  });

  final double amount;
  final String? description;
  final DateTime date;

  Map<String, Object?> toJson() => {
    'amount': amount,
    'description': description,
    'date': formatApiDate(date),
  };
}

class IncomeListItem {
  const IncomeListItem({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  factory IncomeListItem.fromJson(Map<String, Object?> json) => IncomeListItem(
    id: _requiredString(json, 'id'),
    amount: _requiredNumber(json, 'amount'),
    description: _nullableString(json['description']),
    date: _requiredDate(json, 'date'),
    createdAt: _requiredDateTime(json, 'createdAt'),
  );
}

class CategorizeExpenseResponse {
  const CategorizeExpenseResponse({
    required this.success,
    required this.categoryId,
    required this.category,
    required this.confidence,
    required this.requiresManualSelection,
    required this.message,
  });

  final bool success;
  final String? categoryId;
  final String? category;
  final double? confidence;
  final bool requiresManualSelection;
  final String message;

  factory CategorizeExpenseResponse.fromJson(Map<String, Object?> json) =>
      CategorizeExpenseResponse(
        success: _requiredBool(json, 'success'),
        categoryId: _nullableString(json['categoryId']),
        category: _nullableString(json['category']),
        confidence: json['confidence'] is num
            ? (json['confidence'] as num).toDouble()
            : null,
        requiresManualSelection: _requiredBool(json, 'requiresManualSelection'),
        message: _requiredString(json, 'message'),
      );
}

enum TransactionType { expense, income }

class TransactionListItem {
  const TransactionListItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryName,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String? categoryName;
  final DateTime date;
  final DateTime createdAt;

  factory TransactionListItem.fromExpense(ExpenseListItem expense) =>
      TransactionListItem(
        id: expense.id,
        type: TransactionType.expense,
        amount: expense.amount,
        description: expense.description,
        categoryName: expense.category.name,
        date: expense.date,
        createdAt: expense.createdAt,
      );

  factory TransactionListItem.fromIncome(IncomeListItem income) =>
      TransactionListItem(
        id: income.id,
        type: TransactionType.income,
        amount: income.amount,
        description: income.description?.trim().isNotEmpty == true
            ? income.description!.trim()
            : 'Gelir',
        categoryName: null,
        date: income.date,
        createdAt: income.createdAt,
      );
}

String formatApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

Map<String, Object?> readJsonObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw const FormatException('Expected a JSON object.');
}

List<Object?> readJsonList(Object? value) {
  if (value is List<Object?>) return value;
  throw const FormatException('Expected a JSON array.');
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) =>
    readJsonObject(json[key]);

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

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Expected $key to be a boolean.');
}

String? _nullableString(Object? value) {
  if (value == null || value is String) return value as String?;
  throw const FormatException('Expected a nullable string.');
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final date = DateTime.tryParse(value);
  if (date != null) return DateTime(date.year, date.month, date.day);
  throw FormatException('Expected $key to be a date.');
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final dateTime = DateTime.tryParse(value);
  if (dateTime != null) return dateTime;
  throw FormatException('Expected $key to be a date-time.');
}
