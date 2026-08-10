import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import 'service_providers.dart';
import 'business_provider.dart';

// Expense List Provider (filtered by selected business)
final expenseListProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) {
    print('⚠️ expenseListProvider: businessId is null, returning empty list');
    return [];
  }
  
  print('💰 Fetching expenses for business: $businessId');
  final expenseService = ref.watch(expenseServiceProvider);
  try {
    final expenses = await expenseService.getExpensesByBusiness(businessId);
    print('✅ Fetched ${expenses.length} expenses');
    return expenses;
  } catch (e) {
    print('❌ Error fetching expenses for business $businessId: $e');
    rethrow;
  }
});

// Expense Filter Provider
final expenseFilterProvider = StateProvider<String>((ref) => 'All');

// Filtered Expense List Provider
final filteredExpenseListProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  final filter = ref.watch(expenseFilterProvider);
  
  return expensesAsync.when(
    data: (expenses) {
      if (filter == 'All') {
        return AsyncValue.data(expenses);
      }
      
      final filtered = expenses.where((expense) {
        if (filter == 'Fixed') return expense.isFixed;
        if (filter == 'Variable') return !expense.isFixed;
        return true;
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Total expenses calculation
final totalExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.when(
    data: (expenses) => expenses.fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Fixed expenses total
final fixedExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.when(
    data: (expenses) => expenses
        .where((e) => e.isFixed)
        .fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Variable expenses total
final variableExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expenseListProvider);
  return expensesAsync.when(
    data: (expenses) => expenses
        .where((e) => !e.isFixed)
        .fold<double>(0, (sum, e) => sum + e.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});
