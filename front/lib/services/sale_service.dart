import '../models/sale.dart';
import 'api_client.dart';

class SaleService {
  final ApiClient _apiClient;

  SaleService(this._apiClient);

  // Record a sale
  Future<Sale> recordSale({
    required String businessId,
    required String productId,
    double quantity = 1,
  }) async {
    final response = await _apiClient.post(
      '/sales',
      data: {
        'business': businessId,
        'product': productId,
        'quantity': quantity,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return Sale.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Get sales by business
  Future<List<Sale>> getSalesByBusiness(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (from != null) queryParameters['from'] = from.toIso8601String();
    if (to != null) queryParameters['to'] = to.toIso8601String();

    final response = await _apiClient.get(
      '/sales/business/$businessId',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    final data = response.data as Map<String, dynamic>;
    final saleList = data['data'] as List;

    return saleList
        .map((json) => Sale.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get daily summary
  Future<DailySummary> getDailySummary(
    String businessId, {
    DateTime? date,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (date != null) {
      queryParameters['date'] = date.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get(
      '/sales/business/$businessId/daily-summary',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    final data = response.data as Map<String, dynamic>;
    return DailySummary.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Get daily profit report
  Future<DailyProfitReport> getDailyProfitReport(
    String businessId, {
    DateTime? date,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (date != null) {
      queryParameters['date'] = date.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get(
      '/sales/business/$businessId/daily-profit',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    final data = response.data as Map<String, dynamic>;
    return DailyProfitReport.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Delete sale (undo)
  Future<void> deleteSale(String id) async {
    await _apiClient.delete('/sales/$id');
  }
}
