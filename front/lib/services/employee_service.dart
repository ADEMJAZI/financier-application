import '../models/employee.dart';
import 'api_client.dart';

class EmployeeService {
  final ApiClient _client;

  EmployeeService(this._client);

  Future<List<Employee>> getEmployees(String businessId) async {
    final response = await _client.get<Map<String, dynamic>>(
        '/employees/business/$businessId');
    final body = response.data as Map<String, dynamic>? ?? {};
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((json) => Employee.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> createEmployee(Map<String, dynamic> data) async {
    final response =
        await _client.post<Map<String, dynamic>>('/employees', data: data);
    final body = response.data as Map<String, dynamic>;
    return Employee.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Employee> updateEmployee(
      String employeeId, Map<String, dynamic> data) async {
    final response = await _client.put<Map<String, dynamic>>(
        '/employees/$employeeId',
        data: data);
    final body = response.data as Map<String, dynamic>;
    return Employee.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Employee> recordPayment(
      String employeeId, Map<String, dynamic> data) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/employees/$employeeId/payments',
      data: data,
    );
    final body = response.data as Map<String, dynamic>;
    return Employee.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Employee> deactivateEmployee(String employeeId) async {
    // Backend has a dedicated PATCH /:id/deactivate endpoint
    final response = await _client.patch<Map<String, dynamic>>(
      '/employees/$employeeId/deactivate',
    );
    final body = response.data as Map<String, dynamic>;
    return Employee.fromJson(body['data'] as Map<String, dynamic>);
  }
}
