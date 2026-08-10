import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste.dart';
import 'service_providers.dart';
import 'business_provider.dart';
import 'product_provider.dart';
import 'reports_provider.dart';
import 'sale_provider.dart';
import 'order_providers.dart';

final wasteListProvider = FutureProvider.autoDispose<List<Waste>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(wasteServiceProvider);
  return await service.getWaste(businessId);
});

class WasteNotifier extends AsyncNotifier<List<Waste>> {
  @override
  Future<List<Waste>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(wasteServiceProvider);
    return await service.getWaste(businessId);
  }

  Future<void> createWaste(Map<String, dynamic> data) async {
    final service = ref.read(wasteServiceProvider);
    final waste = await service.createWaste(data);
    
    // Invalidate ALL providers affected by stock changes
    ref.invalidate(wasteListProvider);
    ref.invalidate(productListProvider);
    ref.invalidate(reorderSuggestionsProvider);
    ref.invalidate(todayDailyProfitProvider);
    ref.invalidate(cashFlowReportProvider);
    // Also invalidate sales/order providers since waste affects stock
    ref.invalidate(todaySalesSummaryProvider);
    ref.invalidate(todayProfitReportProvider);
    ref.invalidate(activeBusinessDailySummaryProvider);
    ref.invalidate(activeBusinessDailyProfitProvider);
    ref.invalidate(activeBusinessOrdersProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([waste, ...current]);
  }

  Future<void> deleteWaste(String wasteId) async {
    final service = ref.read(wasteServiceProvider);
    await service.deleteWaste(wasteId);
    
    // Invalidate ALL providers affected by stock changes
    ref.invalidate(wasteListProvider);
    ref.invalidate(productListProvider);
    ref.invalidate(reorderSuggestionsProvider);
    ref.invalidate(todayDailyProfitProvider);
    ref.invalidate(cashFlowReportProvider);
    // Also invalidate sales/order providers since waste affects stock
    ref.invalidate(todaySalesSummaryProvider);
    ref.invalidate(todayProfitReportProvider);
    ref.invalidate(activeBusinessDailySummaryProvider);
    ref.invalidate(activeBusinessDailyProfitProvider);
    ref.invalidate(activeBusinessOrdersProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((w) => w.id != wasteId).toList());
  }
}

final wasteNotifierProvider =
    AsyncNotifierProvider<WasteNotifier, List<Waste>>(WasteNotifier.new);

// Monthly total loss
final monthlyWasteLossProvider = Provider<double>((ref) {
  final wasteAsync = ref.watch(wasteListProvider);
  return wasteAsync.when(
    data: (wastes) {
      final now = DateTime.now();
      return wastes
          .where((w) => w.date.year == now.year && w.date.month == now.month)
          .fold(0.0, (sum, w) => sum + w.estimatedLoss);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
