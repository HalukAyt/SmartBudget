import '../models/dashboard_models.dart';
import 'api_client.dart';

abstract interface class DashboardDataService {
  Future<MonthlyDashboard> getMonthly({int? year, int? month});

  Future<MonthlyAnalysisResponse> getMonthlyAnalysis({int? year, int? month});
}

class DashboardService implements DashboardDataService {
  const DashboardService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<MonthlyDashboard> getMonthly({int? year, int? month}) async {
    final path = year == null || month == null
        ? '/api/dashboard/monthly'
        : '/api/dashboard/monthly?year=$year&month=$month';
    final result = await _apiClient.get(path);
    return MonthlyDashboard.fromJson(_readObject(result));
  }

  @override
  Future<MonthlyAnalysisResponse> getMonthlyAnalysis({
    int? year,
    int? month,
  }) async {
    final body = year == null || month == null
        ? <String, Object?>{}
        : <String, Object?>{'year': year, 'month': month};
    final result = await _apiClient.post('/api/ai/monthly-summary', body: body);
    return MonthlyAnalysisResponse.fromJson(_readObject(result));
  }

  Map<String, Object?> _readObject(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const ApiException(
      ApiErrorType.server,
      'Sunucudan beklenmeyen bir yanıt alındı.',
    );
  }
}
