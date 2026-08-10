import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  // Create a new order (checkout cart)
  Future<Order> createOrder(String businessId, List<Map<String, dynamic>> items) async {
    final response = await _apiClient.post(
      '/orders',
      data: {
        'business': businessId,
        'items': items,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return Order.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Get orders for a business
  Future<List<Order>> getOrdersByBusiness(String businessId) async {
    final response = await _apiClient.get('/orders/business/$businessId');

    final data = response.data as Map<String, dynamic>;
    final ordersList = data['data'] as List;

    return ordersList
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get daily summary for a business
  Future<OrderDailySummary> getDailySummary(String businessId, {DateTime? date}) async {
    final queryParams = date != null 
        ? '?date=${date.toIso8601String().split('T')[0]}'
        : '';
    
    final response = await _apiClient.get('/orders/business/$businessId/daily-summary$queryParams');

    final data = response.data as Map<String, dynamic>;
    return OrderDailySummary.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Get daily profit report for a business
  Future<OrderDailyProfit> getDailyProfitReport(String businessId, {DateTime? date}) async {
    final queryParams = date != null 
        ? '?date=${date.toIso8601String().split('T')[0]}'
        : '';
    
    final response = await _apiClient.get('/orders/business/$businessId/daily-profit$queryParams');

    final data = response.data as Map<String, dynamic>;
    return OrderDailyProfit.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Get order by ID
  Future<Order> getOrderById(String orderId) async {
    final response = await _apiClient.get('/orders/$orderId');

    final data = response.data as Map<String, dynamic>;
    return Order.fromJson(data['data'] as Map<String, dynamic>);
  }

  // Void an order
  Future<Order> voidOrder(String orderId, String reason) async {
    final response = await _apiClient.patch(
      '/orders/$orderId/void',
      data: {'reason': reason},
    );

    final data = response.data as Map<String, dynamic>;
    return Order.fromJson(data['data'] as Map<String, dynamic>);
  }
}