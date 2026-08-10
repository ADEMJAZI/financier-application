import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import 'service_providers.dart';
import 'business_provider.dart';

// Filter state
final auditLogCollectionFilterProvider = StateProvider<String>((ref) => '');
final auditLogSearchQueryProvider = StateProvider<String>((ref) => '');

final auditLogListProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  final service = ref.watch(auditLogServiceProvider);
  final collection = ref.watch(auditLogCollectionFilterProvider);
  return await service.getAuditLogs(
    businessId,
    collection: collection.isEmpty ? null : collection,
  );
});

final filteredAuditLogsProvider = Provider<AsyncValue<List<AuditLog>>>((ref) {
  final logsAsync = ref.watch(auditLogListProvider);
  final query = ref.watch(auditLogSearchQueryProvider).toLowerCase();

  return logsAsync.when(
    data: (logs) {
      if (query.isEmpty) return AsyncValue.data(logs);
      return AsyncValue.data(logs
          .where((log) =>
              log.collection.toLowerCase().contains(query) ||
              log.action.toLowerCase().contains(query) ||
              log.changeDescriptions.any((d) => d.toLowerCase().contains(query)))
          .toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
