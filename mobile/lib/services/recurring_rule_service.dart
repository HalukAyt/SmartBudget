import '../models/recurring_models.dart';
import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class RecurringRuleDataService {
  Future<List<RecurringRuleListItem>> getAll();
  Future<RecurringRuleListItem> create(CreateRecurringRuleRequest request);
  Future<void> delete(String id);
  Future<RecurringRealizeResult> realize(
    String ruleId,
    RealizeRecurringRuleRequest request,
  );
}

class RecurringRuleService implements RecurringRuleDataService {
  const RecurringRuleService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<RecurringRuleListItem>> getAll() async {
    final result = await _apiClient.get('/api/recurring-rules');
    try {
      return readJsonList(result)
          .map((item) => RecurringRuleListItem.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Planlanan kayıtlar beklenen biçimde alınamadı.',
      );
    }
  }

  @override
  Future<RecurringRuleListItem> create(
    CreateRecurringRuleRequest request,
  ) async {
    final result = await _apiClient.post(
      '/api/recurring-rules',
      body: request.toJson(),
    );
    try {
      return RecurringRuleListItem.fromJson(readJsonObject(result));
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Planlanan kayıt yanıtı beklenen biçimde alınamadı.',
      );
    }
  }

  @override
  Future<void> delete(String id) =>
      _apiClient.delete('/api/recurring-rules/$id');

  @override
  Future<RecurringRealizeResult> realize(
    String ruleId,
    RealizeRecurringRuleRequest request,
  ) async {
    final result = await _apiClient.post(
      '/api/recurring-rules/$ruleId/realize',
      body: request.toJson(),
    );
    try {
      return RecurringRealizeResult.fromJson(readJsonObject(result));
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Gerçekleştirme yanıtı beklenen biçimde alınamadı.',
      );
    }
  }
}
