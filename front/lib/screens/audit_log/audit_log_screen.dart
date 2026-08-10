import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/audit_log_provider.dart';
import '../../models/audit_log.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredLogsAsync = ref.watch(filteredAuditLogsProvider);
    final searchQuery = ref.watch(auditLogSearchQueryProvider);
    final filterCollection = ref.watch(auditLogCollectionFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search changes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                ref.read(auditLogSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      ref.read(auditLogSearchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                PopupMenuButton<String>(
                  initialValue: filterCollection,
                  onSelected: (val) => ref.read(auditLogCollectionFilterProvider.notifier).state = val,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: '', child: Text('All Entities')),
                    const PopupMenuItem(value: 'Product', child: Text('Products')),
                    const PopupMenuItem(value: 'Expense', child: Text('Expenses')),
                    const PopupMenuItem(value: 'CustomerDebt', child: Text('Debts')),
                    const PopupMenuItem(value: 'Supplier', child: Text('Suppliers')),
                    const PopupMenuItem(value: 'Employee', child: Text('Employees')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: filterCollection.isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Log entries list
          Expanded(
            child: filteredLogsAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(auditLogListProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return EmptyState(
                    icon: Icons.history,
                    title: 'No Logs Found',
                    message: searchQuery.isNotEmpty || filterCollection.isNotEmpty
                        ? 'Try clearing your filters or search terms.'
                        : 'No changes have been tracked yet.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(auditLogListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: logs.length,
                    itemBuilder: (ctx, i) {
                      final log = logs[i];
                      return _AuditLogCard(log: log, isDark: isDark);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog log;
  final bool isDark;

  const _AuditLogCard({required this.log, required this.isDark});

  Color _actionColor() {
    switch (log.action.toLowerCase()) {
      case 'create':
        return isDark ? AppColors.successDark : AppColors.successLight;
      case 'delete':
        return isDark ? AppColors.dangerDark : AppColors.dangerLight;
      case 'update':
      default:
        return isDark ? AppColors.warningDark : AppColors.warningLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _actionColor();
    final changes = log.changeDescriptions;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        log.actionLabel,
                        style: AppTypography.labelSmall.copyWith(color: color, fontWeight: AppTypography.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      log.collectionLabel,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold),
                    ),
                  ],
                ),
                Text(
                  Formatters.dateTime(log.createdAt),
                  style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
            if (changes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(color: theme.dividerColor),
              const SizedBox(height: AppSpacing.sm),
              ...changes.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        c,
                        style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
