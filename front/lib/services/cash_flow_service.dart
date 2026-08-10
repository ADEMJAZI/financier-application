import '../models/cash_flow_report.dart';
import 'api_client.dart';
import 'package:dio/dio.dart';

class CashFlowService {
  final ApiClient _client;

  CashFlowService(this._client);

  Future<CashFlowSummary> getCashFlowReport(
    String businessId, {
    String groupBy = 'day',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Provide default dates if not specified (last 30 days)
    final now = DateTime.now();
    final defaultStartDate = startDate ?? DateTime(now.year, now.month, 1);
    final defaultEndDate = endDate ?? now;
    
    // Backend expects "from" and "to", not "startDate" and "endDate"
    final queryParams = <String, dynamic>{
      'groupBy': groupBy,
      'from': defaultStartDate.toIso8601String(),
      'to': defaultEndDate.toIso8601String(),
    };

    try {
      final response = await _client.get(
        '/cash-flow/business/$businessId',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final reportData = data['data'] as Map<String, dynamic>;
      
      return CashFlowSummary.fromJson(reportData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Return mock empty data when API doesn't exist (for development)
        return CashFlowSummary(
          totalCashIn: 0,
          totalCashOut: 0,
          netCashFlow: 0,
          nonCashLosses: 0,
          periods: [],
        );
      }
      rethrow;
    }
  }
}
