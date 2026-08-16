import '../models/budget_models.dart';
import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class BudgetDataService {
  Future<List<BudgetListItem>> getAll();
  Future<BudgetListItem> create(CreateBudgetRequest request);
  Future<BudgetListItem> update(String id, UpdateBudgetRequest request);
  Future<void> delete(String id);
}

class BudgetService implements BudgetDataService {
  const BudgetService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<BudgetListItem>> getAll() async {
    final result = await _apiClient.get('/api/budgets');
    try {
      return readJsonList(result)
          .map((item) => BudgetListItem.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }

  @override
  Future<BudgetListItem> create(CreateBudgetRequest request) async {
    final result = await _apiClient.post(
      '/api/budgets',
      body: request.toJson(),
    );
    return _readBudget(result);
  }

  @override
  Future<BudgetListItem> update(String id, UpdateBudgetRequest request) async {
    final result = await _apiClient.put(
      '/api/budgets/$id',
      body: request.toJson(),
    );
    return _readBudget(result);
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/api/budgets/$id');
  }

  BudgetListItem _readBudget(Object? value) {
    try {
      return BudgetListItem.fromJson(readJsonObject(value));
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }
}
