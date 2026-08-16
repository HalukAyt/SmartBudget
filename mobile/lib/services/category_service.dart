import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class CategoryDataService {
  Future<List<CategoryModel>> getAll();
}

class CategoryService implements CategoryDataService {
  const CategoryService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<CategoryModel>> getAll() async {
    final result = await _apiClient.get('/api/categories');
    try {
      return readJsonList(result)
          .map((item) => CategoryModel.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }
}
