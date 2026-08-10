import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_debt.dart';
import 'service_providers.dart';
import 'business_provider.dart';
import 'reports_provider.dart';

// Debt List Provider (filtered by selected business)
final debtListProvider = FutureProvider.autoDispose<List<CustomerDebt>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];

  final debtService = ref.watch(customerDebtServiceProvider);
  return await debtService.getDebtsByBusiness(businessId);
});

// Debt status filter
final debtStatusFilterProvider = StateProvider<String>((ref) => 'all');

// Filtered debts
final filteredDebtListProvider =
    Provider<AsyncValue<List<CustomerDebt>>>((ref) {
  final debtsAsync = ref.watch(debtListProvider);
  final filter = ref.watch(debtStatusFilterProvider);

  return debtsAsync.when(
    data: (debts) {
      if (filter == 'all') return AsyncValue.data(debts);
      return AsyncValue.data(
          debts.where((d) => d.status == filter).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Total debts calculation
final totalDebtsProvider = Provider<double>((ref) {
  final debtsAsync = ref.watch(debtListProvider);
  return debtsAsync.when(
    data: (debts) => debts.fold<double>(0, (sum, d) => sum + d.totalAmount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Unpaid debts count
final unpaidDebtsCountProvider = Provider<int>((ref) {
  final debtsAsync = ref.watch(debtListProvider);
  return debtsAsync.when(
    data: (debts) => debts.where((d) => d.status == 'unpaid').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Remaining amount calculation
final totalRemainingProvider = Provider<double>((ref) {
  final debtsAsync = ref.watch(debtListProvider);
  return debtsAsync.when(
    data: (debts) =>
        debts.fold<double>(0, (sum, d) => sum + d.remainingAmount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Mutable notifier for debt CRUD
class DebtNotifier extends AsyncNotifier<List<CustomerDebt>> {
  @override
  Future<List<CustomerDebt>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(customerDebtServiceProvider);
    return await service.getDebtsByBusiness(businessId);
  }

  Future<void> createDebt(Map<String, dynamic> data) async {
    final service = ref.read(customerDebtServiceProvider);
    final debt = await service.createDebt(CustomerDebt.fromJson({
      '_id': '',
      'business': data['business'],
      'customerName': data['customerName'],
      'totalAmount': data['totalAmount'],
      'paidAmount': 0,
      'status': 'unpaid',
      'payments': [],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }));
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(debtListProvider);
    // Debt totals feed the dashboard outstanding-debts stat — also
    // invalidate cash flow since debt payments are a cash-in source.
    ref.invalidate(cashFlowReportProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, debt]);
  }

  Future<void> addPayment(String debtId, double amount, String? note) async {
    print('🟡 DEBUG [DebtNotifier]: addPayment called');
    print('🟡 DEBUG [DebtNotifier]: debtId: $debtId');
    print('🟡 DEBUG [DebtNotifier]: amount: $amount');
    print('🟡 DEBUG [DebtNotifier]: note: $note');
    
    try {
      final service = ref.read(customerDebtServiceProvider);
      final payment = Payment(
          amount: amount, date: DateTime.now(), note: note);
      
      print('🟡 DEBUG [DebtNotifier]: Calling service.addPayment...');
      final updated = await service.addPayment(debtId, payment);
      
      print('🟡 DEBUG [DebtNotifier]: Payment successful, refreshing state');
      
      // CRITICAL FIX: Invalidate the FutureProvider to force a fresh fetch from API
      // This ensures all computed providers (totalRemaining, unpaidCount, etc.) also update
      ref.invalidate(debtListProvider);
      // Debt payments are cash-in in the cash flow report — invalidate it too.
      ref.invalidate(cashFlowReportProvider);
      
      // Also update local state immediately for instant UI feedback
      _replaceInList(updated);
      
      print('🟡 DEBUG [DebtNotifier]: State refreshed successfully');
    } catch (e, stackTrace) {
      print('🔴 DEBUG [DebtNotifier]: Error in addPayment: $e');
      print('🔴 DEBUG [DebtNotifier]: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    final service = ref.read(customerDebtServiceProvider);
    await service.deleteDebt(debtId);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(debtListProvider);
    // Removing a debt affects cash flow reporting totals.
    ref.invalidate(cashFlowReportProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((d) => d.id != debtId).toList());
  }

  void _replaceInList(CustomerDebt updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final d in current) if (d.id == updated.id) updated else d,
    ]);
  }
}

final debtNotifierProvider =
    AsyncNotifierProvider<DebtNotifier, List<CustomerDebt>>(DebtNotifier.new);

