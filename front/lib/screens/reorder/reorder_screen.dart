import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/reports_provider.dart';
import '../../models/reorder_suggestion.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';

class ReorderScreen extends ConsumerWidget {
  const ReorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suggestionsAsync = ref.watch(reorderSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reorder Suggestions')),
      body: suggestionsAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(reorderSuggestionsProvider),
        ),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return EmptyState(
              icon: Icons.checklist_outlined,
              title: 'All Stock Levels Healthy',
              message: 'None of your products have crossed their low stock/reorder thresholds.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reorderSuggestionsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: suggestions.length,
              itemBuilder: (ctx, i) {
                final s = suggestions[i];
                return _ReorderCard(suggestion: s, isDark: isDark);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  final ReorderSuggestion suggestion;
  final bool isDark;

  const _ReorderCard({required this.suggestion, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color urgencyColor;
    switch (suggestion.urgencyLevel) {
      case 3:
        urgencyColor = isDark ? AppColors.dangerDark : AppColors.dangerLight;
        break;
      case 2:
        urgencyColor = isDark ? AppColors.warningDark : AppColors.warningLight;
        break;
      case 1:
      default:
        urgencyColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
        break;
    }

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
                Expanded(
                  child: Text(
                    suggestion.productName,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    suggestion.urgencyLabel,
                    style: AppTypography.labelSmall.copyWith(color: urgencyColor, fontWeight: AppTypography.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniField(
                    label: 'Current Stock',
                    value: Formatters.quantityWithUnit(suggestion.currentQuantity, suggestion.unit),
                  ),
                ),
                Expanded(
                  child: _MiniField(
                    label: 'Threshold',
                    value: Formatters.quantityWithUnit(suggestion.reorderPoint, suggestion.unit),
                  ),
                ),
                Expanded(
                  child: _MiniField(
                    label: 'Suggested Restock',
                    value: Formatters.quantityWithUnit(suggestion.reorderQuantity, suggestion.unit),
                    valueColor: urgencyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pre-fill restock logic or redirect to record supplier purchase
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jumped to restock: ${suggestion.productName}'),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                label: const Text('Record Supplier Restock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.bold, color: valueColor)),
      ],
    );
  }
}
