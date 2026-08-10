import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../providers/service_providers.dart';
import '../providers/business_provider.dart'; // correct import (not business_providers)
import 'product_provider.dart';
import 'reports_provider.dart';

// ─── Orders list for a business ────────────────────────────────────────────────
final ordersListProvider =
    FutureProvider.family<List<Order>, String>((ref, businessId) async {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getOrdersByBusiness(businessId);
});

// ─── Auto-refresh orders for the active business ────────────────────────────────
final activeBusinessOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final activeBusiness = ref.watch(activeBusinessProvider);
  if (activeBusiness == null) return [];
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getOrdersByBusiness(activeBusiness.id);
});

// ─── Daily summary (revenue + stock consumed) ──────────────────────────────────
final orderDailySummaryProvider =
    FutureProvider.family<OrderDailySummary, String>((ref, businessId) async {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getDailySummary(businessId);
});

final activeBusinessDailySummaryProvider =
    FutureProvider.autoDispose<OrderDailySummary?>((ref) async {
  final activeBusiness = ref.watch(activeBusinessProvider);
  if (activeBusiness == null) return null;
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getDailySummary(activeBusiness.id);
});

// ─── Daily profit (revenue - expenses) ─────────────────────────────────────────
final orderDailyProfitProvider =
    FutureProvider.family<OrderDailyProfit, String>((ref, businessId) async {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getDailyProfitReport(businessId);
});

final activeBusinessDailyProfitProvider =
    FutureProvider.autoDispose<OrderDailyProfit?>((ref) async {
  final activeBusiness = ref.watch(activeBusinessProvider);
  if (activeBusiness == null) return null;
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getDailyProfitReport(activeBusiness.id);
});

// ─── Single order by id ─────────────────────────────────────────────────────────
final orderProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getOrderById(orderId);
});

// ─── Today's orders filtered client-side from the full list ────────────────────
final todaysOrdersProvider = Provider<List<Order>>((ref) {
  final ordersAsync = ref.watch(activeBusinessOrdersProvider);
  return ordersAsync.when(
    data: (orders) {
      final today = DateTime.now();
      return orders.where((order) {
        // Use the `date` field (business date) for filtering
        return order.date.year == today.year &&
            order.date.month == today.month &&
            order.date.day == today.day;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // newest first
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Order Notifier for state mutations (e.g. voiding orders) ─────────────────
class OrderNotifier extends StateNotifier<AsyncValue<void>> {
  OrderNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<Order> voidOrder(String orderId, String reason) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(orderServiceProvider);
      final order = await service.voidOrder(orderId, reason);
      
      // Invalidate all related providers
      ref.invalidate(activeBusinessOrdersProvider);
      // Also invalidate the family provider used by views that pass businessId
      // explicitly — read the active business id to target the right family entry.
      final activeBusiness = ref.read(activeBusinessProvider);
      if (activeBusiness != null) {
        ref.invalidate(ordersListProvider(activeBusiness.id));
      }
      ref.invalidate(activeBusinessDailySummaryProvider);
      ref.invalidate(activeBusinessDailyProfitProvider);
      ref.invalidate(todayDailyProfitProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(reorderSuggestionsProvider);
      ref.invalidate(cashFlowReportProvider);
      
      state = const AsyncValue.data(null);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<void>>(
        (ref) => OrderNotifier(ref));