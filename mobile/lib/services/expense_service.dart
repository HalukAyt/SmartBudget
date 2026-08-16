import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class ExpenseDataService {
  Future<List<ExpenseListItem>> getAll();
  Future<ExpenseListItem> create(CreateExpenseRequest request);
  Future<void> delete(String id);
}

class ExpenseService implements ExpenseDataService {
  const ExpenseService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<ExpenseListItem>> getAll() async {
    final result = await _apiClient.get('/api/expenses');
    try {
      return readJsonList(result)
          .map((item) => ExpenseListItem.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }

  @override
  Future<ExpenseListItem> create(CreateExpenseRequest request) async {
    final result = await _apiClient.post(
      '/api/expenses',
      body: request.toJson(),
    );
    try {
      return ExpenseListItem.fromJson(readJsonObject(result));
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/api/expenses/$id');
  }
}
