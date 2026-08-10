import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cash_register.dart';
import 'service_providers.dart';
import 'active_business_provider.dart';

final cashRegisterListProvider =
    FutureProvider.autoDispose<List<CashRegister>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(cashRegisterServiceProvider);
  return await service.getCashRegisters(businessId);
});

final todayCashRegisterProvider =
    FutureProvider.autoDispose<CashRegister?>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return null;
  final service = ref.watch(cashRegisterServiceProvider);
  return await service.getTodayRegister(businessId);
});

class CashRegisterNotifier extends AsyncNotifier<List<CashRegister>> {
  @override
  Future<List<CashRegister>> build() async {
    final businessId = ref.watch(activeBusinessIdProvider);
    if (businessId == null) return [];
    final service = ref.watch(cashRegisterServiceProvider);
    return await service.getCashRegisters(businessId);
  }

  Future<CashRegister> openRegister(Map<String, dynamic> data) async {
    final service = ref.read(cashRegisterServiceProvider);
    final register = await service.openRegister(data);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(cashRegisterListProvider);
    ref.invalidate(todayCashRegisterProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([register, ...current]);
    return register;
  }

  Future<CashRegister> closeRegister(
      String registerId, double closingBalance) async {
    final service = ref.read(cashRegisterServiceProvider);
    final updated = await service.closeRegister(registerId, closingBalance);
    
    // Invalidate to force fresh fetch from API
    ref.invalidate(cashRegisterListProvider);
    ref.invalidate(todayCashRegisterProvider);
    
    // Also update local state immediately
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final r in current) if (r.id == updated.id) updated else r,
    ]);
    return updated;
  }
}

final cashRegisterNotifierProvider =
    AsyncNotifierProvider<CashRegisterNotifier, List<CashRegister>>(
        CashRegisterNotifier.new);
