import '../models/reorder_suggestion.dart';
import 'api_client.dart';
import 'package:dio/dio.dart';

class ReorderService {
  final ApiClient _client;

  ReorderService(this._client);

  Future<List<ReorderSuggestion>> getReorderSuggestions(
      String businessId) async {
    try {
      final response = await _client
          .get<Map<String, dynamic>>('/reorder/business/$businessId');

      // Backend returns { success: true, data: [...] }
      final responseData = response.data as Map<String, dynamic>? ?? {};
      final raw = responseData['data'] as List<dynamic>? ?? [];

      return raw
          .map((json) =>
              ReorderSuggestion.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.urgencyLevel.compareTo(a.urgencyLevel));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }
}
