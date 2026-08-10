import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_sale.dart';
import 'service_providers.dart';
import 'business_provider.dart';
import 'active_business_provider.dart';
import 'product_provider.dart';
import 'reports_provider.dart';

// Today's Menu Item Sales Summary Provider
final todayMenuItemSalesSummaryProvider = FutureProvider.autoDispose<MenuItemSaleSummary>((ref) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  
  if (activeBusinessId == null) {
    return MenuItemSaleSummary(
      date: DateTime.now(),
      totalRevenue: 0,
      saleCount: 0,
      byMenuItem: [],
    );
  }

  final menuItemSaleService = ref.watch(menuItemSaleServiceProvider);
  return await menuItemSaleService.getDailySummary(
    activeBusinessId,
    date: DateTime.now(),
  );
});

// Today's Daily Profit Report Provider (for manufacturing businesses)
final todayMenuItemProfitProvider = FutureProvider.autoDispose<DailyProfitReport>((ref) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  
  if (activeBusinessId == null) {
    return DailyProfitReport(
      date: DateTime.now(),
      totalRevenue: 0,
      totalExpenses: 0,
      netProfit: 0,
    );
  }

  final menuItemSaleService = ref.watch(menuItemSaleServiceProvider);
  return await menuItemSaleService.getDailyProfitReport(
    activeBusinessId,
    date: DateTime.now(),
  );
});

// Menu Item Sales List Provider (with date range)
final menuItemSalesProvider = FutureProvider.autoDispose.family<List<MenuItemSale>, DateRange?>((ref, dateRange) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  
  if (activeBusinessId == null) {
    return [];
  }

  final menuItemSaleService = ref.watch(menuItemSaleServiceProvider);
  return await menuItemSaleService.getSalesByBusiness(
    activeBusinessId,
    from: dateRange?.from,
    to: dateRange?.to,
  );
});

// Date Range helper class
class DateRange {
  final DateTime from;
  final DateTime to;

  DateRange({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && runtimeType == other.runtimeType && from == other.from && to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}

// Menu Item Sale Notifier - for recording and deleting sales
class MenuItemSaleNotifier extends StateNotifier<AsyncValue<void>> {
  MenuItemSaleNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<MenuItemSale> recordSale({
    required String businessId,
    required String menuItemId,
    double? quantity,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(menuItemSaleServiceProvider);
      final sale = await service.recordSale(
        businessId: businessId,
        menuItemId: menuItemId,
        quantity: quantity,
      );
      
      // Invalidate related providers to refresh
      ref.invalidate(todayMenuItemSalesSummaryProvider);
      ref.invalidate(todayMenuItemProfitProvider);
      ref.invalidate(menuItemSalesProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(reorderSuggestionsProvider);
      ref.invalidate(todayDailyProfitProvider);
      ref.invalidate(cashFlowReportProvider);
      
      state = const AsyncValue.data(null);
      return sale;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteSale(String id) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(menuItemSaleServiceProvider);
      await service.deleteSale(id);
      
      // Invalidate related providers to refresh
      ref.invalidate(todayMenuItemSalesSummaryProvider);
      ref.invalidate(todayMenuItemProfitProvider);
      ref.invalidate(menuItemSalesProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(reorderSuggestionsProvider);
      ref.invalidate(todayDailyProfitProvider);
      ref.invalidate(cashFlowReportProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final menuItemSaleNotifierProvider = StateNotifierProvider<MenuItemSaleNotifier, AsyncValue<void>>((ref) {
  return MenuItemSaleNotifier(ref);
});
