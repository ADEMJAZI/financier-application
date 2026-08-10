import '../models/waste.dart';
import 'api_client.dart';

class WasteService {
  final ApiClient _client;

  WasteService(this._client);

  Future<List<Waste>> getWaste(String businessId) async {
    final response = await _client.get<Map<String, dynamic>>(
        '/waste/business/$businessId');
    final body = response.data as Map<String, dynamic>? ?? {};
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((json) => Waste.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Waste> createWaste(Map<String, dynamic> data) async {
    final response =
        await _client.post<Map<String, dynamic>>('/waste', data: data);
    final body = response.data as Map<String, dynamic>;
    return Waste.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteWaste(String wasteId) async {
    await _client.delete('/waste/$wasteId');
  }
}
