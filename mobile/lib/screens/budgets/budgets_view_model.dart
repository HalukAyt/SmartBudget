import 'package:flutter/foundation.dart';

import '../../models/budget_models.dart';
import '../../models/transaction_models.dart';
import '../../services/api_client.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';

class BudgetsViewModel extends ChangeNotifier {
  BudgetsViewModel({
    required BudgetDataService budgetService,
    required CategoryDataService categoryService,
    int? initialYear,
    int? initialMonth,
  }) : _budgetService = budgetService,
       _categoryService = categoryService,
       _selectedYear = initialYear ?? DateTime.now().year,
       _selectedMonth = initialMonth ?? DateTime.now().month,
       _useFirstBudgetPeriod = initialYear == null || initialMonth == null;

  final BudgetDataService _budgetService;
  final CategoryDataService _categoryService;
  List<BudgetListItem> _budgets = const [];
  List<CategoryModel> _categories = const [];
  final Set<String> _deletingIds = {};
  int _selectedYear;
  int _selectedMonth;
  bool _isLoading = false;
  bool _useFirstBudgetPeriod;
  String? _errorMessage;

  List<BudgetListItem> get budgets => _budgets;
  List<CategoryModel> get categories => _categories;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isDeleting(String id) => _deletingIds.contains(id);

  List<BudgetListItem> get visibleBudgets => _budgets
      .where(
        (budget) =>
            budget.year == _selectedYear && budget.month == _selectedMonth,
      )
      .toList(growable: false);

  Future<void> loadInitial() => _load(includeCategories: true);

  Future<void> retry() => _load(includeCategories: _categories.isEmpty);

  Future<void> refresh() => _load(includeCategories: _categories.isEmpty);

  void selectPeriod({required int year, required int month}) {
    if (year < 2000 || year > 2100 || month < 1 || month > 12) return;
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
  }

  Future<String?> deleteBudget(BudgetListItem budget) async {
    if (_deletingIds.contains(budget.id)) return null;
    _deletingIds.add(budget.id);
    notifyListeners();
    try {
      await _budgetService.delete(budget.id);
      _budgets = _budgets
          .where((candidate) => candidate.id != budget.id)
          .toList(growable: false);
      return null;
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) {
        await refresh();
        return 'Bütçe kaydı bulunamadı veya artık mevcut değil.';
      }
      return error.userMessage;
    } on Object {
      return 'Bütçe silinemedi. Lütfen tekrar deneyin.';
    } finally {
      _deletingIds.remove(budget.id);
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
        _budgetService.getAll(),
        if (includeCategories) _categoryService.getAll(),
      ]);
      _budgets = results[0] as List<BudgetListItem>;
      if (_useFirstBudgetPeriod && _budgets.isNotEmpty) {
        _selectedYear = _budgets.first.year;
        _selectedMonth = _budgets.first.month;
        _useFirstBudgetPeriod = false;
      }
      if (includeCategories) {
        _categories = results[1] as List<CategoryModel>;
      }
    } on ApiException catch (error) {
      _errorMessage = error.userMessage;
    } on Object {
      _errorMessage = 'Bütçeler yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
