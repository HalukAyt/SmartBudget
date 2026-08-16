import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class IncomeDataService {
  Future<List<IncomeListItem>> getAll();
  Future<IncomeListItem> create(CreateIncomeRequest request);
  Future<void> delete(String id);
}

class IncomeService implements IncomeDataService {
  const IncomeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<IncomeListItem>> getAll() async {
    final result = await _apiClient.get('/api/incomes');
    try {
      return readJsonList(result)
          .map((item) => IncomeListItem.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }

  @override
  Future<IncomeListItem> create(CreateIncomeRequest request) async {
    final result = await _apiClient.post(
      '/api/incomes',
      body: request.toJson(),
    );
    try {
      return IncomeListItem.fromJson(readJsonObject(result));
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.delete('/api/incomes/$id');
  }
}
