import '../models/cash_register.dart';
import 'api_client.dart';
import 'package:dio/dio.dart';

class CashRegisterService {
  final ApiClient _client;

  CashRegisterService(this._client);

  Future<List<CashRegister>> getCashRegisters(String businessId) async {
    try {
      // Correct endpoint: /cash-registers/business/:businessId
      final response = await _client.get('/cash-registers/business/$businessId');
      
      final data = response.data as Map<String, dynamic>;
      final registers = data['data'] as List<dynamic>? ?? [];
      
      return registers
          .map((json) => CashRegister.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Return empty list when API doesn't exist (for development)
        return [];
      }
      rethrow;
    }
  }

  Future<CashRegister?> getTodayRegister(String businessId) async {
    try {
      final registers = await getCashRegisters(businessId);
      final today = DateTime.now();
      return registers.firstWhere((r) {
        final d = r.openedAt;
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      });
    } catch (_) {
      return null;
    }
  }

  Future<CashRegister> openRegister(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .post<Map<String, dynamic>>('/cash-registers', data: data);
      
      final responseData = response.data!;
      final registerData = responseData['data'] as Map<String, dynamic>;
      
      return CashRegister.fromJson(registerData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Register already open - extract the error message
        final errorData = e.response?.data as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'A cash register is already open for this business today';
        throw Exception(message);
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Cash register API not implemented yet');
      }
      rethrow;
    }
  }

  Future<CashRegister> closeRegister(
      String registerId, double closingBalance) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/cash-registers/$registerId/close',
        data: {'closingBalance': closingBalance},
      );
      
      final responseData = response.data!;
      final registerData = responseData['data'] as Map<String, dynamic>;
      
      return CashRegister.fromJson(registerData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cash register not found');
      }
      rethrow;
    }
  }
}
