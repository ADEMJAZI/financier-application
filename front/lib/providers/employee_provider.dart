import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import 'service_providers.dart';
import 'business_provider.dart';

final employeeListProvider = FutureProvider.autoDispose<List<Employee>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(employeeServiceProvider);
  return await service.getEmployees(businessId);
});

class EmployeeNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(employeeServiceProvider);
    return await service.getEmployees(businessId);
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    final service = ref.read(employeeServiceProvider);
    final employee = await service.createEmployee(data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(employeeListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, employee]);
  }

  Future<void> recordPayment(
      String employeeId, Map<String, dynamic> data) async {
    final service = ref.read(employeeServiceProvider);
    final updated = await service.recordPayment(employeeId, data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(employeeListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  Future<void> deactivateEmployee(String employeeId) async {
    final service = ref.read(employeeServiceProvider);
    final updated = await service.deactivateEmployee(employeeId);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(employeeListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  void _replaceInList(Employee updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final e in current) if (e.id == updated.id) updated else e,
    ]);
  }
}

final employeeNotifierProvider =
    AsyncNotifierProvider<EmployeeNotifier, List<Employee>>(
        EmployeeNotifier.new);
