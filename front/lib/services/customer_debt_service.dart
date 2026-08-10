import '../models/customer_debt.dart';
import 'api_client.dart';
import 'package:dio/dio.dart';

class CustomerDebtService {
  final ApiClient _apiClient;
  
  CustomerDebtService(this._apiClient);
  
  // Create a new customer debt
  Future<CustomerDebt> createDebt(CustomerDebt debt) async {
    try {
      final response = await _apiClient.post(
        '/debts',
        data: debt.toJson(),
      );
      
      final data = response.data as Map<String, dynamic>;
      return CustomerDebt.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Mock response for development when API doesn't exist
        final mockDebt = debt.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return mockDebt;
      }
      rethrow;
    }
  }
  
  // Get debts by business ID
  Future<List<CustomerDebt>> getDebtsByBusiness(String businessId) async {
    try {
      final response = await _apiClient.get('/debts/business/$businessId');
      
      final data = response.data as Map<String, dynamic>;
      final debtList = data['data'] as List;
      
      return debtList
          .map((json) => CustomerDebt.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Return empty list when API doesn't exist (for development)
        return [];
      }
      rethrow;
    }
  }
  
  // Get debt by ID
  Future<CustomerDebt> getDebtById(String id) async {
    try {
      final response = await _apiClient.get('/debts/$id');
      
      final data = response.data as Map<String, dynamic>;
      return CustomerDebt.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Debt not found');
      }
      rethrow;
    }
  }
  
  // Add payment to debt
  Future<CustomerDebt> addPayment(String id, Payment payment) async {
    print('🌐 DEBUG [CustomerDebtService]: addPayment called');
    print('🌐 DEBUG [CustomerDebtService]: POST /debts/$id/payments');
    print('🌐 DEBUG [CustomerDebtService]: Payment data: ${payment.toJson()}');
    
    try {
      final response = await _apiClient.post(
        '/debts/$id/payments',
        data: payment.toJson(),
      );
      
      print('🌐 DEBUG [CustomerDebtService]: Response received: ${response.statusCode}');
      print('🌐 DEBUG [CustomerDebtService]: Response data: ${response.data}');
      
      final data = response.data as Map<String, dynamic>;
      final result = CustomerDebt.fromJson(data['data'] as Map<String, dynamic>);
      
      print('🌐 DEBUG [CustomerDebtService]: Payment successful');
      return result;
    } on DioException catch (e) {
      print('🔴 DEBUG [CustomerDebtService]: DioException: ${e.message}');
      print('🔴 DEBUG [CustomerDebtService]: Status code: ${e.response?.statusCode}');
      print('🔴 DEBUG [CustomerDebtService]: Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('API endpoint not found - make sure backend is running');
      }
      
      if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data?['message'] ?? 'Invalid payment data';
        throw Exception(errorMsg);
      }
      
      throw Exception('Failed to record payment: ${e.message}');
    } catch (e) {
      print('🔴 DEBUG [CustomerDebtService]: Unexpected error: $e');
      rethrow;
    }
  }
  
  // Delete debt
  Future<void> deleteDebt(String id) async {
    try {
      await _apiClient.delete('/debts/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Silently succeed when API doesn't exist (for development)
        return;
      }
      rethrow;
    }
  }
}
