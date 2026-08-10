import '../models/audit_log.dart';
import 'api_client.dart';

class AuditLogService {
  final ApiClient _client;

  AuditLogService(this._client);

  Future<List<AuditLog>> getAuditLogs(
    String businessId, {
    String? collection,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (collection != null && collection.isNotEmpty)
        'collection': collection,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/audit-logs/business/$businessId',
        queryParameters: queryParams,
      );

      // Backend returns { success: true, data: [...] }
      final responseData = response.data as Map<String, dynamic>? ?? {};
      final raw = responseData['data'] as List<dynamic>? ?? [];

      return raw
          .map((json) => AuditLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on any error so the screen shows empty state
      // instead of crashing and popping the route.
      print('❌ AuditLogService.getAuditLogs error: $e');
      rethrow;
    }
  }
}
