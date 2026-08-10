import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';

/// Full screen listing all detected anomalies.
/// Reachable from the More menu.
class AnomalyListScreen extends ConsumerWidget {
  const AnomalyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final anomaliesAsync = ref.watch(aiAnomaliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Anomaly Detection'),
      ),
      body: anomaliesAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(aiAnomaliesProvider),
        ),
        data: (anomalies) {
          if (anomalies.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Anomalies',
              message:
                  'Everything looks normal. No spending or revenue anomalies detected.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(aiAnomaliesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: anomalies.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final a = anomalies[i];
                final severityColor = a.severity == 'high'
                    ? (isDark
                        ? AppColors.dangerDark
                        : AppColors.dangerLight)
                    : a.severity == 'medium'
                        ? (isDark
                            ? AppColors.warningDark
                            : AppColors.warningLight)
                        : (isDark
                            ? AppColors.infoDark
                            : AppColors.infoLight);

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm),
                          ),
                          child: Icon(
                            a.severity == 'high'
                                ? Icons.warning_amber_rounded
                                : a.severity == 'medium'
                                    ? Icons.error_outline
                                    : Icons.info_outline,
                            color: severityColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.type
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: AppTypography
                                          .labelSmall
                                          .copyWith(
                                        color: severityColor,
                                        fontWeight:
                                            AppTypography.semiBold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal:
                                                AppSpacing.sm,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: severityColor
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppSpacing
                                                  .radiusFull),
                                    ),
                                    child: Text(
                                      a.severity,
                                      style: AppTypography
                                          .labelSmall
                                          .copyWith(
                                        color: severityColor,
                                        fontWeight:
                                            AppTypography.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(a.message,
                                  style: AppTypography.bodyMedium),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  _DetailChip(
                                    label: 'Expected',
                                    value: Formatters.currency(
                                        a.expectedValue),
                                    color: isDark
                                        ? AppColors.successDark
                                        : AppColors.successLight,
                                  ),
                                  const SizedBox(
                                      width: AppSpacing.sm),
                                  _DetailChip(
                                    label: 'Actual',
                                    value: Formatters.currency(
                                        a.value),
                                    color: isDark
                                        ? AppColors.dangerDark
                                        : AppColors.dangerLight,
                                  ),
                                ],
                              ),
                              if (a.category != null) ...[
                                const SizedBox(
                                    height: AppSpacing.xs),
                                Text(
                                  'Category: ${a.category}',
                                  style: AppTypography.labelSmall
                                      .copyWith(
                                    color: theme
                                        .colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                    color: color.withOpacity(0.7))),
            Text(value,
                style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: AppTypography.semiBold)),
          ],
        ),
      ),
    );
  }
}
