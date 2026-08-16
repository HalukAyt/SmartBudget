import 'package:flutter/foundation.dart';

import '../../models/dashboard_models.dart';
import '../../services/api_client.dart';
import '../../services/dashboard_service.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required DashboardDataService service})
    : _service = service;

  final DashboardDataService _service;

  MonthlyDashboard? _data;
  MonthlyAnalysisResponse? _analysis;
  String? _errorMessage;
  String? _aiErrorMessage;
  bool _isLoading = false;
  bool _isAiLoading = false;
  bool _usesDefaultPeriod = true;
  int? _requestedYear;
  int? _requestedMonth;

  MonthlyDashboard? get data => _data;
  MonthlyAnalysisResponse? get analysis => _analysis;
  String? get errorMessage => _errorMessage;
  String? get aiErrorMessage => _aiErrorMessage;
  bool get isLoading => _isLoading;
  bool get isAiLoading => _isAiLoading;

  Future<void> loadInitial() => _load(useDefaultPeriod: true);

  Future<void> selectPeriod({required int year, required int month}) {
    if (year < 2000 || year > 2100 || month < 1 || month > 12) {
      return Future.value();
    }
    return _load(year: year, month: month, useDefaultPeriod: false);
  }

  Future<void> retry() => _load(
    year: _requestedYear,
    month: _requestedMonth,
    useDefaultPeriod: _usesDefaultPeriod,
  );

  Future<void> refresh() => _load(
    year: _requestedYear,
    month: _requestedMonth,
    useDefaultPeriod: _usesDefaultPeriod,
    preserveAnalysis: true,
  );

  Future<void> _load({
    int? year,
    int? month,
    required bool useDefaultPeriod,
    bool preserveAnalysis = false,
  }) async {
    if (_isLoading) return;
    _usesDefaultPeriod = useDefaultPeriod;
    _requestedYear = useDefaultPeriod ? null : year;
    _requestedMonth = useDefaultPeriod ? null : month;
    if (!preserveAnalysis) {
      _data = null;
      _analysis = null;
      _aiErrorMessage = null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getMonthly(year: year, month: month);
      _data = result;
    } on ApiException catch (error) {
      _errorMessage = error.userMessage;
    } on Object {
      _errorMessage = 'Dashboard verileri yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateAnalysis() async {
    if (_isAiLoading || _data == null) return;
    _isAiLoading = true;
    _aiErrorMessage = null;
    notifyListeners();

    try {
      _analysis = await _service.getMonthlyAnalysis(
        year: _usesDefaultPeriod ? null : _data!.year,
        month: _usesDefaultPeriod ? null : _data!.month,
      );
    } on Object {
      _aiErrorMessage =
          'AI analizi şu anda oluşturulamadı. Daha sonra tekrar deneyebilirsin.';
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }
}
