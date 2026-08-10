import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'service_providers.dart';
import 'business_provider.dart';
import 'reports_provider.dart';
import 'sale_provider.dart';

// Product List Provider (filtered by selected business)
final productListProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) {
    print('⚠️ productListProvider: businessId is null, returning empty list');
    return [];
  }

  print('📦 Fetching products for business: $businessId');
  final productService = ref.watch(productServiceProvider);
  try {
    final products = await productService.getProductsByBusiness(businessId);
    print('✅ Fetched ${products.length} products');
    return products;
  } catch (e) {
    print('❌ Error fetching products for business $businessId: $e');
    rethrow;
  }
});

// Product Search Query Provider
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Product List Provider (with search)
final filteredProductListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();

  return productsAsync.when(
    data: (products) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(products);
      }

      final filtered = products.where((product) {
        return product.name.toLowerCase().contains(searchQuery) ||
               product.unit.toLowerCase().contains(searchQuery);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(productServiceProvider);
    return await service.getProductsByBusiness(businessId);
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    final service = ref.read(productServiceProvider);
    final product = await service.createProduct(data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(productListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, product]);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final service = ref.read(productServiceProvider);
    final updated = await service.updateProduct(id, data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(productListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  Future<void> deleteProduct(String id) async {
    final service = ref.read(productServiceProvider);
    await service.deleteProduct(id);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(productListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((p) => p.id != id).toList());
  }

  Future<void> restockProduct(String id, double quantity, double? unitPrice) async {
    final service = ref.read(productServiceProvider);
    final updated = await service.restockProduct(id, quantity, unitPrice);
    
    // Invalidate ALL providers affected by stock changes
    ref.invalidate(productListProvider);
    ref.invalidate(reorderSuggestionsProvider);
    ref.invalidate(todayDailyProfitProvider);
    ref.invalidate(cashFlowReportProvider);
    // Also invalidate resale sale providers
    ref.invalidate(todaySalesSummaryProvider);
    ref.invalidate(todayProfitReportProvider);
    // NOTE: order providers (activeBusinessOrdersProvider etc.) are invalidated
    // at the checkout UI layer to avoid a circular import with order_providers.dart
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  void _replaceInList(Product updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final p in current) if (p.id == updated.id) updated else p,
    ]);
  }
}

final productNotifierProvider =
    AsyncNotifierProvider<ProductNotifier, List<Product>>(ProductNotifier.new);

