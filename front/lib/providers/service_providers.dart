import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/product_service.dart';
import '../services/expense_service.dart';
import '../services/customer_debt_service.dart';
import '../services/sale_service.dart';
import '../services/reserve_service.dart';
import '../services/cash_register_service.dart';
import '../services/waste_service.dart';
import '../services/supplier_service.dart';
import '../services/employee_service.dart';
import '../services/reorder_service.dart';
import '../services/cash_flow_service.dart';
import '../services/audit_log_service.dart';
import '../services/menu_item_service.dart';
import '../services/menu_item_sale_service.dart';
import '../services/order_service.dart';
import '../services/ai_service.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// Business Service Provider
final businessServiceProvider = Provider<BusinessService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BusinessService(apiClient);
});

// Product Service Provider
final productServiceProvider = Provider<ProductService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductService(apiClient);
});

// Expense Service Provider
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseService(apiClient);
});

// Customer Debt Service Provider
final customerDebtServiceProvider = Provider<CustomerDebtService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerDebtService(apiClient);
});

// Reserve Service Provider
final reserveServiceProvider = Provider<ReserveService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReserveService(apiClient);
});

// Cash Register Service Provider
final cashRegisterServiceProvider = Provider<CashRegisterService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CashRegisterService(apiClient);
});

// Waste Service Provider
final wasteServiceProvider = Provider<WasteService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WasteService(apiClient);
});

// Supplier Service Provider
final supplierServiceProvider = Provider<SupplierService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupplierService(apiClient);
});

// Employee Service Provider
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeService(apiClient);
});

// Reorder Service Provider
final reorderServiceProvider = Provider<ReorderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReorderService(apiClient);
});

// Cash Flow Service Provider
final cashFlowServiceProvider = Provider<CashFlowService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CashFlowService(apiClient);
});

// Audit Log Service Provider
final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuditLogService(apiClient);
});

// Sale Service Provider
final saleServiceProvider = Provider<SaleService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SaleService(apiClient);
});

// Menu Item Service Provider
final menuItemServiceProvider = Provider<MenuItemService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MenuItemService(apiClient);
});

// Menu Item Sale Service Provider
final menuItemSaleServiceProvider = Provider<MenuItemSaleService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MenuItemSaleService(apiClient);
});

// Order Service Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

// AI Service Provider
final aiServiceProvider = Provider<AiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiService(apiClient);
});
