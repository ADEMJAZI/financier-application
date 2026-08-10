import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import 'service_providers.dart';
import 'active_business_provider.dart';

// Menu Items Provider - fetches menu items for the active business
final menuItemsProvider = FutureProvider.autoDispose<List<MenuItem>>((ref) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  
  if (activeBusinessId == null) {
    return [];
  }

  final menuItemService = ref.watch(menuItemServiceProvider);
  return await menuItemService.getMenuItemsByBusiness(
    activeBusinessId,
    isActive: true, // Only fetch active items by default
  );
});

// All Menu Items Provider (including inactive) - for management screen
final allMenuItemsProvider = FutureProvider.autoDispose<List<MenuItem>>((ref) async {
  final activeBusinessId = ref.watch(activeBusinessIdProvider);
  
  if (activeBusinessId == null) {
    return [];
  }

  final menuItemService = ref.watch(menuItemServiceProvider);
  return await menuItemService.getMenuItemsByBusiness(activeBusinessId);
});

// Menu Item Notifier - for CRUD operations
class MenuItemNotifier extends StateNotifier<AsyncValue<void>> {
  MenuItemNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> createMenuItem({
    required String businessId,
    required String name,
    required double sellingPrice,
    List<Map<String, dynamic>>? recipe,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(menuItemServiceProvider);
      await service.createMenuItem(
        businessId: businessId,
        name: name,
        sellingPrice: sellingPrice,
        recipe: recipe,
      );
      
      // Invalidate the menu items list to refresh
      ref.invalidate(menuItemsProvider);
      ref.invalidate(allMenuItemsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateMenuItem({
    required String id,
    String? name,
    double? sellingPrice,
    bool? isActive,
    List<Map<String, dynamic>>? recipe,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(menuItemServiceProvider);
      await service.updateMenuItem(
        id: id,
        name: name,
        sellingPrice: sellingPrice,
        isActive: isActive,
        recipe: recipe,
      );
      
      // Invalidate the menu items list to refresh
      ref.invalidate(menuItemsProvider);
      ref.invalidate(allMenuItemsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deactivateMenuItem(String id) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(menuItemServiceProvider);
      await service.deactivateMenuItem(id);
      
      // Invalidate the menu items list to refresh
      ref.invalidate(menuItemsProvider);
      ref.invalidate(allMenuItemsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String id) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(menuItemServiceProvider);
      await service.deleteMenuItem(id);
      
      // Invalidate the menu items list to refresh
      ref.invalidate(menuItemsProvider);
      ref.invalidate(allMenuItemsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final menuItemNotifierProvider = StateNotifierProvider<MenuItemNotifier, AsyncValue<void>>((ref) {
  return MenuItemNotifier(ref);
});
