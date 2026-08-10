import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import 'auth_provider.dart';
import 'service_providers.dart';
import 'active_business_provider.dart';
export 'active_business_provider.dart';

// Business List Provider
final businessListProvider = FutureProvider.autoDispose<List<Business>>((ref) async {
  final businessService = ref.watch(businessServiceProvider);
  
  // Check if user is authenticated first
  final authAsync = ref.watch(authProvider);
  final isAuthenticated = authAsync.when(
    data: (authState) => authState.status == AuthStatus.authenticated,
    loading: () => false,
    error: (e, s) => false,
  );
  
  if (!isAuthenticated) {
    return [];
  }
  
  try {
    return await businessService.getBusinesses();
  } catch (e) {
    print('❌ Error fetching businesses: $e');
    rethrow;
  }
});

// Selected Business Provider (using active business)
final selectedBusinessProvider = FutureProvider.autoDispose<Business?>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) {
    print('⚠️ selectedBusinessProvider: businessId is null');
    return null;
  }
  
  // Check if user is authenticated first
  final authAsync = ref.watch(authProvider);
  final isAuthenticated = authAsync.when(
    data: (authState) => authState.status == AuthStatus.authenticated,
    loading: () => false,
    error: (e, s) => false,
  );
  
  if (!isAuthenticated) {
    return null;
  }
  
  final businessService = ref.watch(businessServiceProvider);
  try {
    return await businessService.getBusinessById(businessId);
  } catch (e) {
    print('❌ Error fetching business $businessId: $e');
    rethrow;
  }
});

// Auto-restore active business when the business list loads and nothing is selected
final businessAutoRestoreProvider = Provider<void>((ref) {
  final businessesAsync = ref.watch(businessListProvider);
  final notifier = ref.read(activeBusinessProvider.notifier);

  businessesAsync.whenData((businesses) {
    if (ref.read(activeBusinessProvider) == null && businesses.isNotEmpty) {
      notifier.restoreFromBusinesses(businesses);
    }
  });
});

// Legacy alias — prefer activeBusinessIdProvider in new code
final selectedBusinessIdProvider = Provider<String?>((ref) {
  ref.watch(businessAutoRestoreProvider);
  return ref.watch(activeBusinessIdProvider);
});
