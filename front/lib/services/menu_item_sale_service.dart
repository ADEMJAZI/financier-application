import 'package:dio/dio.dart';
import '../models/menu_item_sale.dart';
import 'api_client.dart';

class MenuItemSaleService {
  final ApiClient _client;

  MenuItemSaleService(this._client);

  // Record a menu item sale
  Future<MenuItemSale> recordSale({
    required String businessId,
    required String menuItemId,
    double? quantity,
  }) async {
    try {
      final data = <String, dynamic>{
        'business': businessId,
        'menuItem': menuItemId,
      };
      
      if (quantity != null) {
        data['quantity'] = quantity;
      }

      final response = await _client.post<Map<String, dynamic>>(
        '/menu-item-sales',
        data: data,
      );

      return MenuItemSale.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Failed to record sale';
        throw Exception(message);
      }
      rethrow;
    }
  }

  // Get sales by business
  Future<List<MenuItemSale>> getSalesByBusiness(
    String businessId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = from.toIso8601String();
      }
      if (to != null) {
        queryParams['to'] = to.toIso8601String();
      }

      final response = await _client.get<Map<String, dynamic>>(
        '/menu-item-sales/business/$businessId',
        queryParameters: queryParams,
      );

      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((json) => MenuItemSale.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get daily summary
  Future<MenuItemSaleSummary> getDailySummary(
    String businessId, {
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }

      final response = await _client.get<Map<String, dynamic>>(
        '/menu-item-sales/business/$businessId/daily-summary',
        queryParameters: queryParams,
      );

      return MenuItemSaleSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get daily profit report
  Future<DailyProfitReport> getDailyProfitReport(
    String businessId, {
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }

      final response = await _client.get<Map<String, dynamic>>(
        '/menu-item-sales/business/$businessId/daily-profit',
        queryParameters: queryParams,
      );

      return DailyProfitReport.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete a sale (undo)
  Future<void> deleteSale(String id) async {
    try {
      await _client.delete<Map<String, dynamic>>('/menu-item-sales/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Sale not found');
      }
      rethrow;
    }
  }
}
