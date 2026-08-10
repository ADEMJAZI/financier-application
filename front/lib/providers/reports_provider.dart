import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cash_flow_report.dart';
import '../models/reorder_suggestion.dart';
import '../models/business.dart';
import 'service_providers.dart';
import 'business_provider.dart';
import 'active_business_provider.dart';
import 'sale_provider.dart';
import 'order_providers.dart';

// ─── Date / groupBy filter state ───────────────────────────────────────────────
final reportsGroupByProvider = StateProvider<String>((ref) => 'month');

final reportsStartDateProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  final groupBy = ref.watch(reportsGroupByProvider);
  
  switch (groupBy) {
    case 'day':
      // Today
      return DateTime(now.year, now.month, now.day);
    case 'week':
      // Start of current week (Monday)
      final weekday = now.weekday;
      return now.subtract(Duration(days: weekday - 1));
    case 'month':
    default:
      // First day of current month
      return DateTime(now.year, now.month, 1);
  }
});

final reportsEndDateProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  final groupBy = ref.watch(reportsGroupByProvider);
  
  switch (groupBy) {
    case 'day':
      // End of today
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    case 'week':
      // End of current week (Sunday)
      final weekday = now.weekday;
      final endOfWeek = now.add(Duration(days: 7 - weekday));
      return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
    case 'month':
      // End of current month
      return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    default:
      return null; // Service will default to "now"
  }
});

// ─── Unified daily profit data ─────────────────────────────────────────────────
class DailyProfitData {
  final DateTime date;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  DailyProfitData({
    required this.date,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });
}

/// Branches by businessType so both Dashboard and Reports
/// consume identical data without knowing the source.
final todayDailyProfitProvider =
    FutureProvider.autoDispose<DailyProfitData>((ref) async {
  final activeBusiness = ref.watch(activeBusinessProvider);

  if (activeBusiness == null) {
    return DailyProfitData(
      date: DateTime.now(),
      totalRevenue: 0,
      totalExpenses: 0,
      netProfit: 0,
    );
  }

  if (activeBusiness.businessType == BusinessType.manufacturing) {
    final report = await ref.watch(activeBusinessDailyProfitProvider.future);
    if (report == null) {
      return DailyProfitData(
        date: DateTime.now(),
        totalRevenue: 0,
        totalExpenses: 0,
        netProfit: 0,
      );
    }
    return DailyProfitData(
      date: report.date,
      totalRevenue: report.totalRevenue,
      totalExpenses: report.totalExpenses,
      netProfit: report.netProfit,
    );
  } else {
    final report = await ref.watch(todayProfitReportProvider.future);
    return DailyProfitData(
      date: report.date,
      totalRevenue: report.totalRevenue,
      totalExpenses: report.totalExpenses,
      netProfit: report.netProfit,
    );
  }
});

// ─── Cash flow (for Reports screen with user-selected filters) ────────────────
final cashFlowReportProvider =
    FutureProvider.autoDispose<CashFlowSummary>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) {
    return CashFlowSummary(
      totalCashIn: 0,
      totalCashOut: 0,
      netCashFlow: 0,
      nonCashLosses: 0,
      periods: [],
    );
  }
  final service = ref.watch(cashFlowServiceProvider);
  final groupBy = ref.watch(reportsGroupByProvider);
  final startDate = ref.watch(reportsStartDateProvider);
  final endDate = ref.watch(reportsEndDateProvider);

  return service.getCashFlowReport(
    businessId,
    groupBy: groupBy,
    startDate: startDate,
    endDate: endDate,
  );
});

// ─── Dashboard monthly cash flow (independent, always current month) ───────────
final dashboardMonthlyCashFlowProvider =
    FutureProvider.autoDispose<CashFlowSummary>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) {
    return CashFlowSummary(
      totalCashIn: 0,
      totalCashOut: 0,
      netCashFlow: 0,
      nonCashLosses: 0,
      periods: [],
    );
  }
  final service = ref.watch(cashFlowServiceProvider);
  final now = DateTime.now();
  
  return service.getCashFlowReport(
    businessId,
    groupBy: 'month',
    startDate: DateTime(now.year, now.month, 1), // First day of current month
    endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59), // Last day of current month
  );
});

// ─── Reorder suggestions (unchanged) ──────────────────────────────────────────
final reorderSuggestionsProvider =
    FutureProvider.autoDispose<List<ReorderSuggestion>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(reorderServiceProvider);
  return service.getReorderSuggestions(businessId);
});
