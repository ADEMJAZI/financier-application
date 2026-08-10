import '../models/expense.dart';
import 'api_client.dart';
import 'package:dio/dio.dart';

class ExpenseService {
  final ApiClient _apiClient;
  
  ExpenseService(this._apiClient);
  
  // Create a new expense
  Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await _apiClient.post(
        '/expenses',
        data: expense.toJson(),
      );
      
      final data = response.data as Map<String, dynamic>;
      return Expense.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Mock response for development when API doesn't exist
        final mockExpense = expense.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return mockExpense;
      }
      rethrow;
    }
  }
  
  // Get expenses by business ID
  Future<List<Expense>> getExpensesByBusiness(String businessId) async {
    try {
      final response = await _apiClient.get('/expenses/business/$businessId');
      
      final data = response.data as Map<String, dynamic>;
      final expenseList = data['data'] as List;
      
      return expenseList
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Return empty list when API doesn't exist (for development)
        return [];
      }
      rethrow;
    }
  }
  
  // Get expense by ID
  Future<Expense> getExpenseById(String id) async {
    try {
      final response = await _apiClient.get('/expenses/$id');
      
      final data = response.data as Map<String, dynamic>;
      return Expense.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Expense not found');
      }
      rethrow;
    }
  }
  
  // Update expense
  Future<Expense> updateExpense(String id, Expense expense) async {
    try {
      final response = await _apiClient.put(
        '/expenses/$id',
        data: expense.toJson(),
      );
      
      final data = response.data as Map<String, dynamic>;
      return Expense.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Mock response for development when API doesn't exist
        return expense.copyWith(updatedAt: DateTime.now());
      }
      rethrow;
    }
  }
  
  // Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      await _apiClient.delete('/expenses/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Silently succeed when API doesn't exist (for development)
        return;
      }
      rethrow;
    }
  }
}
