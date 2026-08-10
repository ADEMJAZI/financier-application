import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import 'service_providers.dart';
import 'active_business_provider.dart';
import 'product_provider.dart';
import 'reports_provider.dart';

// Today's Sales Summary Provider (for resale businesses)
final todaySalesSummaryProvider =
    FutureProvider.autoDispose<DailySummary>((ref) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  if (activeBusinessId == null) {
    return DailySummary(
      date: DateTime.now(),
      totalRevenue: 0,
      saleCount: 0,
      byProduct: [],
    );
  }

  final saleService = ref.watch(saleServiceProvider);
  return saleService.getDailySummary(activeBusinessId, date: DateTime.now());
});

// Today's Profit Report Provider (for resale businesses)
final todayProfitReportProvider =
    FutureProvider.autoDispose<DailyProfitReport>((ref) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  if (activeBusinessId == null) {
    return DailyProfitReport(
      date: DateTime.now(),
      totalRevenue: 0,
      totalExpenses: 0,
      netProfit: 0,
    );
  }

  final saleService = ref.watch(saleServiceProvider);
  return saleService.getDailyProfitReport(activeBusinessId,
      date: DateTime.now());
});

// Sale Notifier — record and delete sales
class SaleNotifier extends StateNotifier<AsyncValue<void>> {
  SaleNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<Sale> recordSale({
    required String businessId,
    required String productId,
    required double quantity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(saleServiceProvider);
      final sale = await service.recordSale(
        businessId: businessId,
        productId: productId,
        quantity: quantity,
      );
      // Invalidate ALL providers affected by stock/sales changes
      ref.invalidate(todaySalesSummaryProvider);
      ref.invalidate(todayProfitReportProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(reorderSuggestionsProvider);
      ref.invalidate(todayDailyProfitProvider);
      ref.invalidate(cashFlowReportProvider);
      // NOTE: order providers are invalidated at the checkout UI layer
      // to avoid a circular import with order_providers.dart
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
      final service = ref.read(saleServiceProvider);
      await service.deleteSale(id);
      // Invalidate ALL providers affected by stock/sales changes
      ref.invalidate(todaySalesSummaryProvider);
      ref.invalidate(todayProfitReportProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(reorderSuggestionsProvider);
      ref.invalidate(todayDailyProfitProvider);
      ref.invalidate(cashFlowReportProvider);
      // NOTE: order providers are invalidated at the checkout UI layer
      // to avoid a circular import with order_providers.dart
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final saleNotifierProvider =
    StateNotifierProvider<SaleNotifier, AsyncValue<void>>(
        (ref) => SaleNotifier(ref));
