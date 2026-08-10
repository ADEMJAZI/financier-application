import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ai_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';

/// Bottom sheet for "Smart Quick Add".
/// The user types a natural-language expense description, AI parses it,
/// and the result is returned to the caller so it can pre-fill the
/// existing add-expense form. Does NOT auto-save.
class SmartQuickAddSheet extends ConsumerStatefulWidget {
  const SmartQuickAddSheet({super.key});

  @override
  ConsumerState<SmartQuickAddSheet> createState() => _SmartQuickAddSheetState();
}

class _SmartQuickAddSheetState extends ConsumerState<SmartQuickAddSheet> {
  final _ctrl = TextEditingController();

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

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                width: 40,
                height: 4,
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
                    color: primary.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm)),
                child:
                    Icon(Icons.auto_awesome, color: primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Smart Quick Add', style: AppTypography.h3),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Describe an expense in plain text — AI will fill the form for you.',
              style: AppTypography.bodySmall.copyWith(
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Text input
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. "electricity bill 250 dinars" or "اشتريت مواد بـ 80 دينار"',
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
                        ref.read(nlExpenseProvider.notifier).parse(text);
                      },
                icon: nlState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(
                    nlState.isLoading ? 'Analyzing...' : 'Parse with AI'),
              ),
            ),

            // Error
            if (nlState.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.dangerLight.withOpacity(0.3)),
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

            // Result preview — tapping "Fill Form" returns data
            if (nlState.result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ParsedPreviewFill(
                result: nlState.result!,
                isDark: isDark,
                primary: primary,
                onFillForm: () {
                  final parsed = nlState.result!;
                  ref.read(nlExpenseProvider.notifier).reset();
                  // Pop the sheet and return the parsed data as a Map
                  Navigator.of(context).pop(<String, dynamic>{
                    'amount': parsed.amount,
                    'category': parsed.category,
                    'description': parsed.description,
                  });
                },
                onCancel: () {
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

class _ParsedPreviewFill extends StatelessWidget {
  final dynamic result;
  final bool isDark;
  final Color primary;
  final VoidCallback onFillForm;
  final VoidCallback onCancel;

  const _ParsedPreviewFill({
    required this.result,
    required this.isDark,
    required this.primary,
    required this.onFillForm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = (result.confidence as double) * 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle_outline, color: primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('AI Parsed Result',
                style: AppTypography.labelMedium.copyWith(
                    color: primary,
                    fontWeight: AppTypography.semiBold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull)),
              child: Text('${confidence.toStringAsFixed(0)}%',
                  style:
                      AppTypography.labelSmall.copyWith(color: primary)),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
              label: 'Amount',
              value: Formatters.currency(result.amount as double)),
          _InfoRow(
              label: 'Category', value: result.category as String),
          _InfoRow(
              label: 'Description',
              value: result.description as String),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onFillForm,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Fill Form'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

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
                  color: theme.colorScheme.onSurface.withOpacity(0.55))),
        ),
        Expanded(
            child: Text(value,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: AppTypography.semiBold))),
      ]),
    );
  }
}
