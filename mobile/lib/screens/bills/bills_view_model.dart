import 'package:flutter/foundation.dart';

import '../../models/bill_models.dart';
import '../../models/recurring_models.dart';
import '../../services/api_client.dart';
import '../../services/bill_service.dart';
import '../../services/recurring_rule_service.dart';

enum BillFilter { all, electricity, water, naturalGas }

class BillsViewModel extends ChangeNotifier {
  BillsViewModel({
    required BillDataService service,
    required RecurringRuleDataService recurringRuleService,
  }) : _service = service,
       _recurringRuleService = recurringRuleService;

  final BillDataService _service;
  final RecurringRuleDataService _recurringRuleService;
  List<BillListItem> _bills = const [];
  List<BillTrendPoint> _trend = const [];
  List<RecurringRuleListItem> _recurringRules = const [];
  final Set<String> _deletingIds = {};
  final Set<String> _realizingRuleIds = {};
  BillFilter _filter = BillFilter.all;
  BillType _trendType = BillType.electricity;
  bool _isListLoading = false;
  bool _isTrendLoading = false;
  bool _isRecurringLoading = false;
  String? _listError;
  String? _trendError;
  String? _recurringErrorMessage;

  List<BillListItem> get bills => _bills;
  List<BillTrendPoint> get trend => _trend;
  BillFilter get filter => _filter;
  BillType get trendType => _trendType;
  bool get isListLoading => _isListLoading;
  bool get isTrendLoading => _isTrendLoading;
  String? get listError => _listError;
  String? get trendError => _trendError;
  bool isDeleting(String id) => _deletingIds.contains(id);

  List<RecurringRuleListItem> get recurringBillRules => _recurringRules
      .where((rule) => rule.recordType == RecurringRecordType.bill)
      .toList(growable: false);
  bool get isRecurringLoading => _isRecurringLoading;
  String? get recurringErrorMessage => _recurringErrorMessage;
  bool isRealizingRule(String ruleId) => _realizingRuleIds.contains(ruleId);

  List<BillListItem> get visibleBills {
    final type = switch (_filter) {
      BillFilter.all => null,
      BillFilter.electricity => BillType.electricity,
      BillFilter.water => BillType.water,
      BillFilter.naturalGas => BillType.naturalGas,
    };
    return type == null
        ? List.unmodifiable(_bills)
        : _bills.where((bill) => bill.billType == type).toList(growable: false);
  }

  List<BillTrendPoint> get visibleTrend {
    final points = _trend
        .where((point) => point.billType == _trendType)
        .toList(growable: false);
    points.sort((a, b) {
      final year = a.year.compareTo(b.year);
      return year != 0 ? year : a.month.compareTo(b.month);
    });
    return points;
  }

  Future<void> loadInitial() async {
    await Future.wait([loadBills(), loadTrend(), loadRecurringRules()]);
  }

  Future<void> refresh() async {
    await Future.wait([loadBills(), loadTrend(), loadRecurringRules()]);
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
          'Planlanan faturalar yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      _isRecurringLoading = false;
      notifyListeners();
    }
  }

  /// Realizes a bill recurring rule for the given month with a confirmed
  /// real amount. On success, reloads bills, trend and recurring rules so
  /// the Bill -> Expense sync effects are reflected everywhere.
  Future<String?> realizeRecurringRule(
    RecurringRuleListItem rule, {
    required int year,
    required int month,
    required double amount,
    double? consumptionValue,
  }) async {
    if (_realizingRuleIds.contains(rule.id)) return null;
    _realizingRuleIds.add(rule.id);
    notifyListeners();
    try {
      await _recurringRuleService.realize(
        rule.id,
        RealizeRecurringRuleRequest(
          year: year,
          month: month,
          amount: amount,
          consumptionValue: consumptionValue,
        ),
      );
      await refresh();
      return null;
    } on ApiException catch (error) {
      return error.userMessage;
    } on Object {
      return 'Fatura gerçekleştirilemedi. Lütfen tekrar deneyin.';
    } finally {
      _realizingRuleIds.remove(rule.id);
      notifyListeners();
    }
  }

  Future<void> loadBills() async {
    if (_isListLoading) return;
    _isListLoading = true;
    _listError = null;
    notifyListeners();
    try {
      _bills = await _service.getAll();
    } on ApiException catch (error) {
      _listError = error.userMessage;
    } on Object {
      _listError = 'Faturalar yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      _isListLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrend() async {
    if (_isTrendLoading) return;
    _isTrendLoading = true;
    _trendError = null;
    notifyListeners();
    try {
      _trend = await _service.getTrends();
    } on Object {
      _trendError = 'Trend verileri şu anda yüklenemedi.';
    } finally {
      _isTrendLoading = false;
      notifyListeners();
    }
  }

  void selectFilter(BillFilter value) {
    _filter = value;
    notifyListeners();
  }

  void selectTrendType(BillType value) {
    if (value == BillType.unknown) return;
    _trendType = value;
    notifyListeners();
  }

  Future<String?> deleteBill(BillListItem bill) async {
    if (_deletingIds.contains(bill.id)) return null;
    _deletingIds.add(bill.id);
    notifyListeners();
    try {
      await _service.delete(bill.id);
      _bills = _bills.where((item) => item.id != bill.id).toList();
      await loadTrend();
      return null;
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) {
        await refresh();
        return 'Fatura kaydı bulunamadı veya artık mevcut değil.';
      }
      return error.userMessage;
    } on Object {
      return 'Fatura silinemedi. Lütfen tekrar deneyin.';
    } finally {
      _deletingIds.remove(bill.id);
      notifyListeners();
    }
  }
}
