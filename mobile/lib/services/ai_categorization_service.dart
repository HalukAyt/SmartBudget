import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class AiCategorizationDataService {
  Future<CategorizeExpenseResponse> categorize(String description);
}

class AiCategorizationService implements AiCategorizationDataService {
  const AiCategorizationService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CategorizeExpenseResponse> categorize(String description) async {
    final result = await _apiClient.post(
      '/api/ai/categorize-expense',
      body: {'description': description.trim()},
    );
    try {
      return CategorizeExpenseResponse.fromJson(readJsonObject(result));
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'AI yanıtı işlenemedi. Kategoriyi manuel olarak seçebilirsin.',
      );
    }
  }
}
