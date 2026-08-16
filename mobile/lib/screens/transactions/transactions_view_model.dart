import 'package:flutter/foundation.dart';

import '../../models/recurring_models.dart';
import '../../models/transaction_models.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/recurring_rule_service.dart';

enum TransactionFilter { all, expenses, incomes, planned }

class TransactionsViewModel extends ChangeNotifier {
  TransactionsViewModel({
    required ExpenseDataService expenseService,
    required IncomeDataService incomeService,
    required CategoryDataService categoryService,
    required RecurringRuleDataService recurringRuleService,
  }) : _expenseService = expenseService,
       _incomeService = incomeService,
       _categoryService = categoryService,
       _recurringRuleService = recurringRuleService;

  final ExpenseDataService _expenseService;
  final IncomeDataService _incomeService;
  final CategoryDataService _categoryService;
  final RecurringRuleDataService _recurringRuleService;

  List<ExpenseListItem> _expenses = const [];
  List<IncomeListItem> _incomes = const [];
  List<CategoryModel> _categories = const [];
  List<RecurringRuleListItem> _recurringRules = const [];
  final Set<String> _deletingIds = {};
  TransactionFilter _selectedFilter = TransactionFilter.all;
  bool _isLoading = false;
  bool _isRecurringLoading = false;
  String? _errorMessage;
  String? _recurringErrorMessage;

  List<ExpenseListItem> get expenses => _expenses;
  List<IncomeListItem> get incomes => _incomes;
  List<CategoryModel> get categories => _categories;
  TransactionFilter get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isDeleting(String id) => _deletingIds.contains(id);

  /// Income/Expense recurring rules only; Bill rules are surfaced on the
  /// Faturalar screen alongside the rest of the bill data/refresh flow.
  List<RecurringRuleListItem> get recurringRules => _recurringRules
      .where((rule) => rule.recordType != RecurringRecordType.bill)
      .toList(growable: false);
  bool get isRecurringLoading => _isRecurringLoading;
  String? get recurringErrorMessage => _recurringErrorMessage;

  List<TransactionListItem> get visibleTransactions {
    final items = <TransactionListItem>[
      if (_selectedFilter != TransactionFilter.incomes)
        ..._expenses.map(TransactionListItem.fromExpense),
      if (_selectedFilter != TransactionFilter.expenses)
        ..._incomes.map(TransactionListItem.fromIncome),
    ];
    items.sort((left, right) {
      final dateResult = right.date.compareTo(left.date);
      if (dateResult != 0) return dateResult;
      final createdResult = right.createdAt.compareTo(left.createdAt);
      if (createdResult != 0) return createdResult;
      return left.id.compareTo(right.id);
    });
    return items;
  }

  Future<void> loadInitial() => _load(includeCategories: true);

  Future<void> refresh() => _load(includeCategories: _categories.isEmpty);

  Future<void> retry() => _load(includeCategories: _categories.isEmpty);

  void setFilter(TransactionFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
    if (filter == TransactionFilter.planned &&
        _recurringRules.isEmpty &&
        !_isRecurringLoading) {
      loadRecurringRules();
    }
  }

  Future<void> loadRecurringRules() async {
    if (_isRecurringLoading) return;
    _isRecurringLoading = true;
    _recurringErrorMessage = null;
    notifyListeners();
    try {
      _recurringRules = await _recurringRuleService.getAll();
    } on ApiException catch (error) {
      _recurringErrorMessage = error.userMessage;
    } on Object {
      _recurringErrorMessage =
          'Planlanan kayıtlar yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      _isRecurringLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTransaction(TransactionListItem item) async {
    if (_deletingIds.contains(item.id)) return null;
    _deletingIds.add(item.id);
    notifyListeners();
    try {
      if (item.type == TransactionType.expense) {
        await _expenseService.delete(item.id);
        _expenses = _expenses
            .where((expense) => expense.id != item.id)
            .toList(growable: false);
      } else {
        await _incomeService.delete(item.id);
        _incomes = _incomes
            .where((income) => income.id != item.id)
            .toList(growable: false);
      }
      return null;
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) {
        await refresh();
        return 'Kayıt bulunamadı veya artık mevcut değil.';
      }
      return error.userMessage;
    } on Object {
      return 'İşlem silinemedi. Lütfen tekrar deneyin.';
    } finally {
      _deletingIds.remove(item.id);
      notifyListeners();
    }
  }

  Future<void> _load({required bool includeCategories}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _expenseService.getAll(),
        _incomeService.getAll(),
        if (includeCategories) _categoryService.getAll(),
      ]);
      _expenses = results[0] as List<ExpenseListItem>;
      _incomes = results[1] as List<IncomeListItem>;
      if (includeCategories) {
        _categories = results[2] as List<CategoryModel>;
      }
    } on ApiException catch (error) {
      _errorMessage = error.userMessage;
    } on Object {
      _errorMessage = 'İşlemler yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
