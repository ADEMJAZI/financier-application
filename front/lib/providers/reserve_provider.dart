import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reserve.dart';
import 'service_providers.dart';
import 'business_provider.dart';

final reserveListProvider = FutureProvider.autoDispose<List<Reserve>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(reserveServiceProvider);
  return await service.getReserves(businessId);
});

class ReserveNotifier extends AsyncNotifier<List<Reserve>> {
  @override
  Future<List<Reserve>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(reserveServiceProvider);
    return await service.getReserves(businessId);
  }

  Future<void> createReserve(Map<String, dynamic> data) async {
    final service = ref.read(reserveServiceProvider);
    final reserve = await service.createReserve(data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(reserveListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, reserve]);
  }

  Future<void> deposit(String reserveId, double amount, String? note) async {
    final service = ref.read(reserveServiceProvider);
    final updated = await service.deposit(reserveId, amount, note);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(reserveListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  Future<void> withdraw(String reserveId, double amount, String? note) async {
    final service = ref.read(reserveServiceProvider);
    final updated = await service.withdraw(reserveId, amount, note);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(reserveListProvider);
    
    // Also update local state immediately
    _replaceInList(updated);
  }

  Future<void> deleteReserve(String reserveId) async {
    final service = ref.read(reserveServiceProvider);
    await service.deleteReserve(reserveId);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(reserveListProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((r) => r.id != reserveId).toList());
  }

  void _replaceInList(Reserve updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final r in current)
        if (r.id == updated.id) updated else r,
    ]);
  }
}

final reserveNotifierProvider =
    AsyncNotifierProvider<ReserveNotifier, List<Reserve>>(ReserveNotifier.new);
