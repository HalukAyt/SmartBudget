enum BudgetAlertStatus {
  normal,
  warning,
  exceeded,
  unknown;

  factory BudgetAlertStatus.fromJson(Object? value) {
    return switch (value) {
      'Normal' => BudgetAlertStatus.normal,
      'Warning' => BudgetAlertStatus.warning,
      'Exceeded' => BudgetAlertStatus.exceeded,
      _ => BudgetAlertStatus.unknown,
    };
  }
}

class DashboardCategory {
  const DashboardCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory DashboardCategory.fromJson(Map<String, Object?> json) {
    return DashboardCategory(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
    );
  }
}

class CategoryExpenseSummary {
  const CategoryExpenseSummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentageOfTotalExpense,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentageOfTotalExpense;

  factory CategoryExpenseSummary.fromJson(Map<String, Object?> json) {
    return CategoryExpenseSummary(
      categoryId: _requiredString(json, 'categoryId'),
      categoryName: _requiredString(json, 'categoryName'),
      amount: _requiredNumber(json, 'amount'),
      percentageOfTotalExpense: _requiredNumber(
        json,
        'percentageOfTotalExpense',
      ),
    );
  }
}

class BudgetUsageSummary {
  const BudgetUsageSummary({
    required this.budgetId,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.usagePercent,
    required this.alertStatus,
  });

  final String budgetId;
  final DashboardCategory category;
  final double limitAmount;
  final double spentAmount;
  final double usagePercent;
  final BudgetAlertStatus alertStatus;

  factory BudgetUsageSummary.fromJson(Map<String, Object?> json) {
    return BudgetUsageSummary(
      budgetId: _requiredString(json, 'budgetId'),
      category: DashboardCategory.fromJson(_requiredMap(json, 'category')),
      limitAmount: _requiredNumber(json, 'limitAmount'),
      spentAmount: _requiredNumber(json, 'spentAmount'),
      usagePercent: _requiredNumber(json, 'usagePercent'),
      alertStatus: BudgetAlertStatus.fromJson(json['alertStatus']),
    );
  }
}

class CategoryIncreaseSummary {
  const CategoryIncreaseSummary({
    required this.categoryId,
    required this.categoryName,
    required this.increaseAmount,
  });

  final String categoryId;
  final String categoryName;
  final double increaseAmount;

  factory CategoryIncreaseSummary.fromJson(Map<String, Object?> json) {
    return CategoryIncreaseSummary(
      categoryId: _requiredString(json, 'categoryId'),
      categoryName: _requiredString(json, 'categoryName'),
      increaseAmount: _requiredNumber(json, 'increaseAmount'),
    );
  }
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double balance;

  factory MonthlyTrendPoint.fromJson(Map<String, Object?> json) {
    return MonthlyTrendPoint(
      year: _requiredInt(json, 'year'),
      month: _requiredInt(json, 'month'),
      totalIncome: _requiredNumber(json, 'totalIncome'),
      totalExpense: _requiredNumber(json, 'totalExpense'),
      balance: _requiredNumber(json, 'balance'),
    );
  }
}

class MonthlyDashboard {
  const MonthlyDashboard({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryExpenses,
    required this.budgetUsages,
    required this.previousMonthExpenseChangePercent,
    required this.highestSpendingCategory,
    required this.highestIncreaseCategory,
    required this.lastSixMonthsTrend,
  });

  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<CategoryExpenseSummary> categoryExpenses;
  final List<BudgetUsageSummary> budgetUsages;
  final double? previousMonthExpenseChangePercent;
  final CategoryExpenseSummary? highestSpendingCategory;
  final CategoryIncreaseSummary? highestIncreaseCategory;
  final List<MonthlyTrendPoint> lastSixMonthsTrend;

  bool get hasNoFinancialData =>
      totalIncome == 0 &&
      totalExpense == 0 &&
      categoryExpenses.isEmpty &&
      budgetUsages.isEmpty;

  factory MonthlyDashboard.fromJson(Map<String, Object?> json) {
    return MonthlyDashboard(
      year: _requiredInt(json, 'year'),
      month: _requiredInt(json, 'month'),
      totalIncome: _requiredNumber(json, 'totalIncome'),
      totalExpense: _requiredNumber(json, 'totalExpense'),
      balance: _requiredNumber(json, 'balance'),
      categoryExpenses: _requiredList(json, 'categoryExpenses')
          .map((item) => CategoryExpenseSummary.fromJson(_asMap(item)))
          .toList(growable: false),
      budgetUsages: _requiredList(json, 'budgetUsages')
          .map((item) => BudgetUsageSummary.fromJson(_asMap(item)))
          .toList(growable: false),
      previousMonthExpenseChangePercent: _nullableNumber(
        json['previousMonthExpenseChangePercent'],
      ),
      highestSpendingCategory: json['highestSpendingCategory'] == null
          ? null
          : CategoryExpenseSummary.fromJson(
              _asMap(json['highestSpendingCategory']),
            ),
      highestIncreaseCategory: json['highestIncreaseCategory'] == null
          ? null
          : CategoryIncreaseSummary.fromJson(
              _asMap(json['highestIncreaseCategory']),
            ),
      lastSixMonthsTrend: _requiredList(json, 'lastSixMonthsTrend')
          .map((item) => MonthlyTrendPoint.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
}

class MonthlyAnalysisResponse {
  const MonthlyAnalysisResponse({
    required this.success,
    required this.year,
    required this.month,
    required this.analysis,
    required this.requiresManualReview,
    required this.message,
  });

  final bool success;
  final int year;
  final int month;
  final String? analysis;
  final bool requiresManualReview;
  final String message;

  factory MonthlyAnalysisResponse.fromJson(Map<String, Object?> json) {
    return MonthlyAnalysisResponse(
      success: _requiredBool(json, 'success'),
      year: _requiredInt(json, 'year'),
      month: _requiredInt(json, 'month'),
      analysis: json['analysis'] as String?,
      requiresManualReview: _requiredBool(json, 'requiresManualReview'),
      message: _requiredString(json, 'message'),
    );
  }
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) =>
    _asMap(json[key]);

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw const FormatException('Expected a JSON object.');
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is List<Object?>) return value;
  throw FormatException('Expected $key to be a JSON array.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected $key to be a string.');
}

double _requiredNumber(Map<String, Object?> json, String key) {
  final value = _nullableNumber(json[key]);
  if (value != null) return value;
  throw FormatException('Expected $key to be a number.');
}

double? _nullableNumber(Object? value) =>
    value is num ? value.toDouble() : null;

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Expected $key to be an integer.');
}

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Expected $key to be a boolean.');
}
