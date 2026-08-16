import '../models/bill_models.dart';
import '../models/transaction_models.dart';
import 'api_client.dart';

abstract interface class BillDataService {
  Future<List<BillListItem>> getAll();
  Future<List<BillTrendPoint>> getTrends();
  Future<BillListItem> create(CreateBillRequest request);
  Future<void> delete(String id);
}

class BillService implements BillDataService {
  BillService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<BillListItem>> getAll() async {
    try {
      return readJsonList(await _apiClient.get('/api/bills'))
          .map((item) => BillListItem.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Fatura verileri beklenen biçimde alınamadı.',
      );
    }
  }

  @override
  Future<List<BillTrendPoint>> getTrends() async {
    try {
      return readJsonList(await _apiClient.get('/api/bills/trends'))
          .map((item) => BillTrendPoint.fromJson(readJsonObject(item)))
          .toList(growable: false);
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Trend verileri beklenen biçimde alınamadı.',
      );
    }
  }

  @override
  Future<BillListItem> create(CreateBillRequest request) async {
    try {
      return BillListItem.fromJson(
        readJsonObject(
          await _apiClient.post('/api/bills', body: request.toJson()),
        ),
      );
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Fatura yanıtı beklenen biçimde alınamadı.',
      );
    }
  }

  @override
  Future<void> delete(String id) => _apiClient.delete('/api/bills/$id');
}
