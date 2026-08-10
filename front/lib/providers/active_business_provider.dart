import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business.dart';

class ActiveBusinessNotifier extends StateNotifier<Business?> {
  final Ref ref;
  static const String _activeBusinessIdKey = 'active_business_id';

  ActiveBusinessNotifier(this.ref) : super(null);

  Future<void> setActiveBusiness(Business business) async {
    state = business;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeBusinessIdKey, business.id);
      // No need to manually invalidate providers — they watch activeBusinessIdProvider
      // and will automatically rebuild when this state changes
    } catch (e) {
      // SharedPreferences failure is non-fatal — state is already set in memory
    }
  }

  void clearActiveBusiness() {
    state = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_activeBusinessIdKey);
    });
    // Again, no manual invalidation needed — changing state to null will
    // cause activeBusinessIdProvider to emit null, refreshing all watchers
  }

  Future<void> restoreFromBusinesses(List<Business> businesses) async {
    if (businesses.isEmpty) {
      state = null;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_activeBusinessIdKey);
      if (savedId != null) {
        final savedBusiness = businesses.where((b) => b.id == savedId).firstOrNull;
        if (savedBusiness != null) {
          state = savedBusiness;
          return;
        }
      }
      // Saved ID not in this user's list — fall back to first
      state = businesses.first;
      await prefs.setString(_activeBusinessIdKey, businesses.first.id);
    } catch (e) {
      state = businesses.first;
    }
  }
}

// Active Business Provider
final activeBusinessProvider =
    StateNotifierProvider<ActiveBusinessNotifier, Business?>((ref) {
  return ActiveBusinessNotifier(ref);
});

// Convenience provider for active business ID
final activeBusinessIdProvider = Provider<String?>((ref) {
  return ref.watch(activeBusinessProvider)?.id;
});