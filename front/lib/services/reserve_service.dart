import '../models/reserve.dart';
import 'api_client.dart';

class ReserveService {
  final ApiClient _client;

  ReserveService(this._client);

  Future<List<Reserve>> getReserves(String businessId) async {
    final response = await _client.get<Map<String, dynamic>>(
        '/reserves/business/$businessId');
    final data = response.data as Map<String, dynamic>? ?? {};
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((json) => Reserve.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Reserve> createReserve(Map<String, dynamic> data) async {
    final response =
        await _client.post<Map<String, dynamic>>('/reserves', data: data);
    final body = response.data as Map<String, dynamic>;
    return Reserve.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Reserve> deposit(
      String reserveId, double amount, String? note) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reserves/$reserveId/deposit',
      data: {
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return Reserve.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Reserve> withdraw(
      String reserveId, double amount, String? note) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reserves/$reserveId/withdraw',
      data: {
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return Reserve.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReserve(String reserveId) async {
    await _client.delete('/reserves/$reserveId');
  }
}
