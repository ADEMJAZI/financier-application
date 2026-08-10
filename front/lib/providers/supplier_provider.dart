import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import 'service_providers.dart';
import 'business_provider.dart';

final supplierListProvider = FutureProvider.autoDispose<List<Supplier>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(supplierServiceProvider);
  return await service.getSuppliers(businessId);
});

class SupplierNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(supplierServiceProvider);
    return await service.getSuppliers(businessId);
  }

  Future<void> createSupplier(Map<String, dynamic> data) async {
    final service = ref.read(supplierServiceProvider);
    final supplier = await service.createSupplier(data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(supplierListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, supplier]);
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    final service = ref.read(supplierServiceProvider);
    final updated = await service.updateSupplier(id, data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(supplierListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  Future<void> deleteSupplier(String id) async {
    final service = ref.read(supplierServiceProvider);
    await service.deleteSupplier(id);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(supplierListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((s) => s.id != id).toList());
  }

  Future<void> recordPurchase(String supplierId, Map<String, dynamic> data) async {
    final service = ref.read(supplierServiceProvider);
    final updated = await service.recordPurchase(supplierId, data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(supplierListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  void _replaceInList(Supplier updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final s in current) if (s.id == updated.id) updated else s,
    ]);
  }
}

final supplierNotifierProvider =
    AsyncNotifierProvider<SupplierNotifier, List<Supplier>>(SupplierNotifier.new);
