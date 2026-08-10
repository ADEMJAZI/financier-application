import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ai_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/reports_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet that lets the user type a natural-language expense description.
/// The AI parses it, shows a preview, and the user confirms or rejects.
class NlExpenseSheet extends ConsumerStatefulWidget {
  const NlExpenseSheet({super.key});

  @override
  ConsumerState<NlExpenseSheet> createState() => _NlExpenseSheetState();
}

class _NlExpenseSheetState extends ConsumerState<NlExpenseSheet> {
  final _ctrl = TextEditingController();
  String _lastText = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final nlState = ref.watch(nlExpenseProvider);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Title row
            Row(children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm)),
                child: Icon(Icons.auto_awesome, color: primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(l10n.aiExpenseTitle, style: AppTypography.h3),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.aiExpenseSubtitle,
                style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55))),
            const SizedBox(height: AppSpacing.xl),

            // Text input
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.aiExpenseHint,
                prefixIcon: const Icon(Icons.mic_outlined),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              onChanged: (_) {
                if (nlState.result != null || nlState.error != null) {
                  ref.read(nlExpenseProvider.notifier).reset();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Parse button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: nlState.isLoading
                    ? null
                    : () {
                        final text = _ctrl.text.trim();
                        if (text.isEmpty) return;
                        _lastText = text;
                        ref.read(nlExpenseProvider.notifier).parse(text);
                      },
                icon: nlState.isLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(nlState.isLoading
                    ? l10n.aiParsing
                    : l10n.aiParseButton),
              ),
            ),

            // Error
            if (nlState.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.dangerLight.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.dangerLight, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(nlState.error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.dangerLight)),
                  ),
                ]),
              ),
            ],

            // Result preview
            if (nlState.result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ParsedPreview(
                result: nlState.result!,
                isDark: isDark,
                primary: primary,
                onConfirm: () async {
                  final businessId = ref.read(activeBusinessIdProvider);
                  if (businessId == null) return;
                  final ok = await ref
                      .read(nlExpenseProvider.notifier)
                      .confirm(
                          businessId: businessId,
                          originalText: _lastText);
                  if (ok && context.mounted) {
                    ref.invalidate(expenseListProvider);
                    ref.invalidate(cashFlowReportProvider);
                    ref.invalidate(todayDailyProfitProvider);
                    Navigator.of(context).pop();
                    AppSnackbar.success(context, l10n.aiExpenseSaved);
                  }
                },
                onReject: () {
                  ref.read(nlExpenseProvider.notifier).reset();
                  _ctrl.clear();
                },
              ),
            ],

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ParsedPreview extends StatelessWidget {
  final dynamic result; // ParsedExpense
  final bool isDark;
  final Color primary;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const _ParsedPreview({
    required this.result,
    required this.isDark,
    required this.primary,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confidence = (result.confidence as double) * 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle_outline, color: primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.aiParseResult,
                style: AppTypography.labelMedium
                    .copyWith(color: primary, fontWeight: AppTypography.semiBold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull)),
              child: Text('${confidence.toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall.copyWith(color: primary)),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          _Row(label: l10n.amount,
              value: Formatters.currency(result.amount as double)),
          _Row(label: l10n.category, value: result.category as String),
          _Row(label: l10n.description, value: result.description as String),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                child: Text(l10n.aiReject),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                child: Text(l10n.aiConfirmSave),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
        ),
        Expanded(
            child: Text(value,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: AppTypography.semiBold))),
      ]),
    );
  }
}

void showNlExpenseSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NlExpenseSheet(),
  );
}
