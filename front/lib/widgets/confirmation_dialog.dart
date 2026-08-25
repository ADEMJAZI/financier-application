import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_animations.dart';

/// Confirmation dialog for destructive actions. Shows item name prominently.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? itemName,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool isDangerous = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => SlideInWidget(
      direction: SlideDirection.bottom,
      duration: const Duration(milliseconds: 400),
      child: _ConfirmationDialog(
        title: title,
        message: message,
        itemName: itemName,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
      ),
    ),
  );
  return result ?? false;
}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? itemName;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    this.itemName,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      title: Row(
        children: [
          if (isDangerous) ...[
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(title, style: AppTypography.h4),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTypography.bodyMedium),
          if (itemName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.2)),
              ),
              child: Text(
                '"$itemName"',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.semiBold,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDangerous ? theme.colorScheme.error : theme.colorScheme.primary,
            foregroundColor: isDangerous
                ? theme.colorScheme.onError
                : theme.colorScheme.onPrimary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
