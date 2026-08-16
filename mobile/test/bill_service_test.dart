import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartbudget_mobile/models/bill_models.dart';
import 'package:smartbudget_mobile/services/api_client.dart';
import 'package:smartbudget_mobile/services/bill_service.dart';

import 'helpers/fakes.dart';

void main() {
  test('service uses exact list, trend, create and delete endpoints', () async {
    final storage = MemoryTokenStorage()..token = 'token';
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://api.test',
      tokenStorage: storage,
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' && request.url.path == '/api/bills') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/api/bills/trends') {
          return http.Response('[]', 200);
        }
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 'bill-created',
              'billType': 'Electricity',
              'amount': 100,
              'consumptionValue': null,
              'consumptionUnit': 'kWh',
              'billingDate': '2026-08-16',
              'createdAt': '2026-08-16T12:00:00Z',
            }),
            201,
          );
        }
        return http.Response('', 204);
      }),
    );
    final service = BillService(apiClient: client);

    await service.getAll();
    await service.getTrends();
    await service.create(
      CreateBillRequest(
        billType: BillType.electricity,
        amount: 100,
        consumptionValue: null,
        billingDate: DateTime(2026, 8, 16),
      ),
    );
    await service.delete('bill-created');

    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/bills',
      'GET /api/bills/trends',
      'POST /api/bills',
      'DELETE /api/bills/bill-created',
    ]);
    final payload = jsonDecode(requests[2].body) as Map<String, dynamic>;
    expect(payload.keys, {
      'billType',
      'amount',
      'consumptionValue',
      'billingDate',
    });
  });
}
