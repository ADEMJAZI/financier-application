import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable styled button with loading state and primary/secondary/danger variants
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bgColor;
    Color fgColor;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = colorScheme.primary;
        fgColor = colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        bgColor = Colors.transparent;
        fgColor = colorScheme.primary;
        border = BorderSide(color: colorScheme.primary);
        break;
      case AppButtonVariant.danger:
        bgColor = colorScheme.error;
        fgColor = colorScheme.onError;
        break;
    }

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTypography.button.copyWith(color: fgColor)),
            ],
          );

    final button = border != null
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: border,
              backgroundColor: bgColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
            ),
            child: child,
          );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

enum AppButtonVariant { primary, secondary, danger }
