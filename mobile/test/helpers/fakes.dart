import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/ai_categorization_service.dart';
import 'package:smartbudget_mobile/services/auth_service.dart';
import 'package:smartbudget_mobile/services/budget_service.dart';
import 'package:smartbudget_mobile/services/bill_service.dart';
import 'package:smartbudget_mobile/services/category_service.dart';
import 'package:smartbudget_mobile/models/dashboard_models.dart';
import 'package:smartbudget_mobile/models/recurring_models.dart';
import 'package:smartbudget_mobile/models/transaction_models.dart';
import 'package:smartbudget_mobile/models/budget_models.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/services/dashboard_service.dart';
import 'package:smartbudget_mobile/services/expense_service.dart';
import 'package:smartbudget_mobile/services/income_service.dart';
import 'package:smartbudget_mobile/services/recurring_rule_service.dart';
import 'package:smartbudget_mobile/storage/secure_storage_service.dart';

class MemoryTokenStorage implements TokenStorage, TutorialStorage {
  String? token;
  String? email;
  final tutorialSeenUsers = <String>{};

  @override
  Future<void> saveToken(String token) async => this.token = token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<void> saveEmail(String email) async => this.email = email;

  @override
  Future<String?> readEmail() async => email;

  @override
  Future<void> deleteEmail() async => email = null;

  @override
  Future<bool> hasSeenTutorial(String userEmail) async =>
      tutorialSeenUsers.contains(userEmail.trim().toLowerCase());

  @override
  Future<void> markTutorialSeen(String userEmail) async =>
      tutorialSeenUsers.add(userEmail.trim().toLowerCase());
}

AuthService createAuthService({
  required MemoryTokenStorage storage,
  required Future<http.Response> Function(http.Request request) handler,
}) {
  final apiClient = ApiClient(
    baseUrl: 'https://api.example.test',
    tokenStorage: storage,
    httpClient: MockClient(handler),
  );
  return AuthService(apiClient: apiClient, tokenStorage: storage);
}

typedef MonthlyHandler =
    Future<MonthlyDashboard> Function({int? year, int? month});
typedef AnalysisHandler =
    Future<MonthlyAnalysisResponse> Function({int? year, int? month});

class FakeDashboardService implements DashboardDataService {
  FakeDashboardService({this.monthlyHandler, this.analysisHandler});

  MonthlyHandler? monthlyHandler;
  AnalysisHandler? analysisHandler;
  final monthlyCalls = <({int? year, int? month})>[];
  final analysisCalls = <({int? year, int? month})>[];

  @override
  Future<MonthlyDashboard> getMonthly({int? year, int? month}) {
    monthlyCalls.add((year: year, month: month));
    return monthlyHandler?.call(year: year, month: month) ??
        Future.value(sampleDashboard());
  }

  @override
  Future<MonthlyAnalysisResponse> getMonthlyAnalysis({int? year, int? month}) {
    analysisCalls.add((year: year, month: month));
    return analysisHandler?.call(year: year, month: month) ??
        Future.value(
          MonthlyAnalysisResponse(
            success: true,
            year: year ?? 2026,
            month: month ?? 8,
            analysis: 'Finansal verilerin dengeli bir görünüm sunuyor.',
            requiresManualReview: false,
            message: 'Analiz oluşturuldu.',
          ),
        );
  }
}

MonthlyDashboard sampleDashboard({
  int year = 2026,
  int month = 8,
  double totalIncome = 5000,
  double totalExpense = 6250,
  double balance = -1250,
  double? previousChange,
  bool includeCategories = true,
  bool includeBudgets = true,
  bool includeHighestSpending = true,
  bool includeHighestIncrease = true,
}) {
  final category = CategoryExpenseSummary(
    categoryId: '11111111-1111-1111-1111-111111111111',
    categoryName: 'Market',
    amount: 2500,
    percentageOfTotalExpense: 40,
  );
  return MonthlyDashboard(
    year: year,
    month: month,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: balance,
    categoryExpenses: includeCategories ? [category] : const [],
    budgetUsages: includeBudgets
        ? const [
            BudgetUsageSummary(
              budgetId: '22222222-2222-2222-2222-222222222222',
              category: DashboardCategory(
                id: '11111111-1111-1111-1111-111111111111',
                name: 'Market',
              ),
              limitAmount: 2000,
              spentAmount: 2700,
              usagePercent: 135,
              alertStatus: BudgetAlertStatus.exceeded,
            ),
            BudgetUsageSummary(
              budgetId: '33333333-3333-3333-3333-333333333333',
              category: DashboardCategory(
                id: '44444444-4444-4444-4444-444444444444',
                name: 'Ulaşım',
              ),
              limitAmount: 1000,
              spentAmount: 850,
              usagePercent: 85,
              alertStatus: BudgetAlertStatus.warning,
            ),
          ]
        : const [],
    previousMonthExpenseChangePercent: previousChange,
    highestSpendingCategory: includeHighestSpending ? category : null,
    highestIncreaseCategory: includeHighestIncrease
        ? const CategoryIncreaseSummary(
            categoryId: '11111111-1111-1111-1111-111111111111',
            categoryName: 'Market',
            increaseAmount: 600,
          )
        : null,
    lastSixMonthsTrend: List.generate(6, (index) {
      final trendMonth = month - 5 + index;
      return MonthlyTrendPoint(
        year: trendMonth <= 0 ? year - 1 : year,
        month: trendMonth <= 0 ? trendMonth + 12 : trendMonth,
        totalIncome: 4000 + index * 100,
        totalExpense: 3000 + index * 100,
        balance: 1000,
      );
    }),
  );
}

class FakeExpenseService implements ExpenseDataService {
  FakeExpenseService({List<ExpenseListItem>? items}) : items = items ?? [];

  List<ExpenseListItem> items;
  int getAllCalls = 0;
  int createCalls = 0;
  final deletedIds = <String>[];
  CreateExpenseRequest? lastCreateRequest;
  Future<List<ExpenseListItem>> Function()? getAllHandler;
  Future<ExpenseListItem> Function(CreateExpenseRequest request)? createHandler;
  Future<void> Function(String id)? deleteHandler;

  @override
  Future<List<ExpenseListItem>> getAll() async {
    getAllCalls++;
    if (getAllHandler != null) return getAllHandler!();
    return List.of(items);
  }

  @override
  Future<ExpenseListItem> create(CreateExpenseRequest request) async {
    createCalls++;
    lastCreateRequest = request;
    if (createHandler != null) return createHandler!(request);
    final item = sampleExpense(
      id: 'expense-created',
      amount: request.amount,
      description: request.description,
      date: request.date,
      categoryId: request.categoryId,
      isAiCategorized: request.isAiCategorized,
    );
    items = [...items, item];
    return item;
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    items = items.where((item) => item.id != id).toList();
  }
}

class FakeIncomeService implements IncomeDataService {
  FakeIncomeService({List<IncomeListItem>? items}) : items = items ?? [];

  List<IncomeListItem> items;
  int getAllCalls = 0;
  int createCalls = 0;
  final deletedIds = <String>[];
  CreateIncomeRequest? lastCreateRequest;
  Future<List<IncomeListItem>> Function()? getAllHandler;
  Future<IncomeListItem> Function(CreateIncomeRequest request)? createHandler;
  Future<void> Function(String id)? deleteHandler;

  @override
  Future<List<IncomeListItem>> getAll() async {
    getAllCalls++;
    if (getAllHandler != null) return getAllHandler!();
    return List.of(items);
  }

  @override
  Future<IncomeListItem> create(CreateIncomeRequest request) async {
    createCalls++;
    lastCreateRequest = request;
    if (createHandler != null) return createHandler!(request);
    final item = sampleIncome(
      id: 'income-created',
      amount: request.amount,
      description: request.description,
      date: request.date,
    );
    items = [...items, item];
    return item;
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    items = items.where((item) => item.id != id).toList();
  }
}

class FakeCategoryService implements CategoryDataService {
  FakeCategoryService({List<CategoryModel>? items})
    : items = items ?? sampleCategories;

  List<CategoryModel> items;
  int getAllCalls = 0;

  @override
  Future<List<CategoryModel>> getAll() async {
    getAllCalls++;
    return List.of(items);
  }
}

class FakeAiCategorizationService implements AiCategorizationDataService {
  int calls = 0;
  String? lastDescription;
  Future<CategorizeExpenseResponse> Function(String description)? handler;

  @override
  Future<CategorizeExpenseResponse> categorize(String description) async {
    calls++;
    lastDescription = description;
    if (handler != null) return handler!(description);
    return const CategorizeExpenseResponse(
      success: true,
      categoryId: 'category-market',
      category: 'Market',
      confidence: 0.92,
      requiresManualSelection: false,
      message: 'Öneri oluşturuldu.',
    );
  }
}

const sampleCategories = <CategoryModel>[
  CategoryModel(id: 'category-market', name: 'Market'),
  CategoryModel(id: 'category-transport', name: 'Ulaşım'),
];

ExpenseListItem sampleExpense({
  String id = 'expense-1',
  double amount = 1250.50,
  String description = 'Market alışverişi',
  DateTime? date,
  DateTime? createdAt,
  String categoryId = 'category-market',
  bool isAiCategorized = false,
}) => ExpenseListItem(
  id: id,
  amount: amount,
  description: description,
  category: CategoryModel(
    id: categoryId,
    name: categoryId == 'category-transport' ? 'Ulaşım' : 'Market',
  ),
  date: date ?? DateTime(2026, 8, 16),
  createdAt: createdAt ?? DateTime.utc(2026, 8, 16, 12),
  isAiCategorized: isAiCategorized,
);

IncomeListItem sampleIncome({
  String id = 'income-1',
  double amount = 5000,
  String? description = 'Maaş',
  DateTime? date,
  DateTime? createdAt,
}) => IncomeListItem(
  id: id,
  amount: amount,
  description: description,
  date: date ?? DateTime(2026, 8, 15),
  createdAt: createdAt ?? DateTime.utc(2026, 8, 15, 12),
);

class FakeBudgetService implements BudgetDataService {
  FakeBudgetService({List<BudgetListItem>? items}) : items = items ?? [];

  List<BudgetListItem> items;
  int getAllCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  final deletedIds = <String>[];
  CreateBudgetRequest? lastCreateRequest;
  UpdateBudgetRequest? lastUpdateRequest;
  String? lastUpdateId;
  Future<List<BudgetListItem>> Function()? getAllHandler;
  Future<BudgetListItem> Function(CreateBudgetRequest request)? createHandler;
  Future<BudgetListItem> Function(String id, UpdateBudgetRequest request)?
  updateHandler;
  Future<void> Function(String id)? deleteHandler;

  @override
  Future<List<BudgetListItem>> getAll() async {
    getAllCalls++;
    if (getAllHandler != null) return getAllHandler!();
    return List.of(items);
  }

  @override
  Future<BudgetListItem> create(CreateBudgetRequest request) async {
    createCalls++;
    lastCreateRequest = request;
    if (createHandler != null) return createHandler!(request);
    final result = sampleBudget(
      id: 'budget-created',
      categoryId: request.categoryId,
      limitAmount: request.limitAmount,
      month: request.month,
      year: request.year,
    );
    items = [...items, result];
    return result;
  }

  @override
  Future<BudgetListItem> update(String id, UpdateBudgetRequest request) async {
    updateCalls++;
    lastUpdateId = id;
    lastUpdateRequest = request;
    if (updateHandler != null) return updateHandler!(id, request);
    final existing = items.firstWhere(
      (item) => item.id == id,
      orElse: () => sampleBudget(id: id),
    );
    final result = BudgetListItem(
      id: existing.id,
      category: existing.category,
      limitAmount: request.limitAmount,
      month: existing.month,
      year: existing.year,
      spentAmount: existing.spentAmount,
      usagePercent: existing.usagePercent,
      alertStatus: existing.alertStatus,
      createdAt: existing.createdAt,
    );
    items = items.map((item) => item.id == id ? result : item).toList();
    return result;
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    items = items.where((item) => item.id != id).toList();
  }
}

BudgetListItem sampleBudget({
  String id = 'budget-1',
  String categoryId = 'category-market',
  String? categoryName,
  double limitAmount = 2000,
  int month = 8,
  int year = 2026,
  double spentAmount = 2700,
  double usagePercent = 135,
  BudgetAlertStatus alertStatus = BudgetAlertStatus.exceeded,
}) => BudgetListItem(
  id: id,
  category: CategoryModel(
    id: categoryId,
    name:
        categoryName ??
        (categoryId == 'category-transport' ? 'Ulaşım' : 'Market'),
  ),
  limitAmount: limitAmount,
  month: month,
  year: year,
  spentAmount: spentAmount,
  usagePercent: usagePercent,
  alertStatus: alertStatus,
  createdAt: DateTime.utc(2026, 8, 1, 10),
);

class FakeBillService implements BillDataService {
  FakeBillService({List<BillListItem>? items, List<BillTrendPoint>? trend})
    : items = items ?? [],
      trend = trend ?? [];

  List<BillListItem> items;
  List<BillTrendPoint> trend;
  int getAllCalls = 0;
  int getTrendCalls = 0;
  int createCalls = 0;
  final deletedIds = <String>[];
  CreateBillRequest? lastCreateRequest;
  Future<List<BillListItem>> Function()? getAllHandler;
  Future<List<BillTrendPoint>> Function()? getTrendHandler;
  Future<BillListItem> Function(CreateBillRequest request)? createHandler;
  Future<void> Function(String id)? deleteHandler;

  @override
  Future<List<BillListItem>> getAll() async {
    getAllCalls++;
    if (getAllHandler != null) return getAllHandler!();
    return List.of(items);
  }

  @override
  Future<List<BillTrendPoint>> getTrends() async {
    getTrendCalls++;
    if (getTrendHandler != null) return getTrendHandler!();
    return List.of(trend);
  }

  @override
  Future<BillListItem> create(CreateBillRequest request) async {
    createCalls++;
    lastCreateRequest = request;
    if (createHandler != null) return createHandler!(request);
    final item = sampleBill(
      id: 'bill-created',
      billType: request.billType,
      amount: request.amount,
      consumptionValue: request.consumptionValue,
      billingDate: request.billingDate,
    );
    items = [...items, item];
    return item;
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    items = items.where((item) => item.id != id).toList();
  }
}

BillListItem sampleBill({
  String id = 'bill-1',
  BillType billType = BillType.electricity,
  double amount = 450.50,
  double? consumptionValue = 125.5,
  DateTime? billingDate,
}) => BillListItem(
  id: id,
  billType: billType,
  amount: amount,
  consumptionValue: consumptionValue,
  consumptionUnit: billType.defaultUnit,
  billingDate: billingDate ?? DateTime(2026, 8, 16),
  createdAt: DateTime.utc(2026, 8, 16, 12),
);

class FakeRecurringRuleService implements RecurringRuleDataService {
  FakeRecurringRuleService({List<RecurringRuleListItem>? items})
    : items = items ?? [];

  List<RecurringRuleListItem> items;
  int getAllCalls = 0;
  int createCalls = 0;
  int realizeCalls = 0;
  final deletedIds = <String>[];
  CreateRecurringRuleRequest? lastCreateRequest;
  String? lastRealizedRuleId;
  RealizeRecurringRuleRequest? lastRealizeRequest;
  Future<List<RecurringRuleListItem>> Function()? getAllHandler;
  Future<RecurringRuleListItem> Function(CreateRecurringRuleRequest request)?
  createHandler;
  Future<RecurringRealizeResult> Function(
    String ruleId,
    RealizeRecurringRuleRequest request,
  )?
  realizeHandler;
  Future<void> Function(String id)? deleteHandler;

  @override
  Future<List<RecurringRuleListItem>> getAll() async {
    getAllCalls++;
    if (getAllHandler != null) return getAllHandler!();
    return List.of(items);
  }

  @override
  Future<RecurringRuleListItem> create(
    CreateRecurringRuleRequest request,
  ) async {
    createCalls++;
    lastCreateRequest = request;
    if (createHandler != null) return createHandler!(request);
    final item = sampleRecurringRule(
      id: 'recurring-created',
      recordType: request.recordType,
      startDate: request.startDate,
      endDate: request.endDate ?? request.startDate,
      amount: request.amount,
      description: request.description,
      billType: request.billType,
    );
    items = [...items, item];
    return item;
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    items = items.where((item) => item.id != id).toList();
  }

  @override
  Future<RecurringRealizeResult> realize(
    String ruleId,
    RealizeRecurringRuleRequest request,
  ) async {
    realizeCalls++;
    lastRealizedRuleId = ruleId;
    lastRealizeRequest = request;
    if (realizeHandler != null) return realizeHandler!(ruleId, request);
    final rule = items.firstWhere((item) => item.id == ruleId);
    items = items
        .map(
          (item) => item.id == ruleId
              ? RecurringRuleListItem(
                  id: item.id,
                  recordType: item.recordType,
                  startDate: item.startDate,
                  endDate: item.endDate,
                  isActive: item.isActive,
                  amount: item.amount,
                  description: item.description,
                  category: item.category,
                  billType: item.billType,
                  isRealizedThisMonth: true,
                  nextDueDate: item.nextDueDate,
                )
              : item,
        )
        .toList();
    return RecurringRealizeResult(
      recordType: rule.recordType,
      ruleId: ruleId,
      createdRecordId: 'realized-record',
      year: request.year,
      month: request.month,
    );
  }
}

RecurringRuleListItem sampleRecurringRule({
  String id = 'recurring-1',
  RecurringRecordType recordType = RecurringRecordType.income,
  DateTime? startDate,
  DateTime? endDate,
  bool isActive = true,
  double? amount = 45000,
  String? description = 'Maaş',
  CategoryModel? category,
  BillType? billType,
  bool isRealizedThisMonth = false,
  DateTime? nextDueDate,
}) => RecurringRuleListItem(
  id: id,
  recordType: recordType,
  startDate: startDate ?? DateTime(2026, 8, 16),
  endDate: endDate ?? DateTime(2027, 1, 16),
  isActive: isActive,
  amount: amount,
  description: description,
  category: category,
  billType: billType,
  isRealizedThisMonth: isRealizedThisMonth,
  nextDueDate: isRealizedThisMonth
      ? nextDueDate
      : (nextDueDate ?? (startDate ?? DateTime(2026, 8, 16))),
);

List<BillTrendPoint> sampleBillTrend() => [
  for (var month = 3; month <= 8; month++)
    for (final type in const [
      BillType.electricity,
      BillType.water,
      BillType.naturalGas,
    ])
      BillTrendPoint(
        year: 2026,
        month: month,
        billType: type,
        totalAmount: month * 100.0,
        totalConsumption: month == 3 ? null : month * 10.0,
        consumptionUnit: type.defaultUnit,
      ),
];
