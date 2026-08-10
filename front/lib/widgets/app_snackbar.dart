import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (type) {
      case SnackbarType.success:
        backgroundColor = isDark ? AppColors.successDark : AppColors.successLight;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case SnackbarType.error:
        backgroundColor = isDark ? AppColors.dangerDark : AppColors.dangerLight;
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case SnackbarType.warning:
        backgroundColor = isDark ? AppColors.warningDark : AppColors.warningLight;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case SnackbarType.info:
        backgroundColor = isDark ? AppColors.infoDark : AppColors.infoLight;
        textColor = Colors.white;
        icon = Icons.info;
        break;
    }
    
    // Check if the widget is still mounted before showing snackbar
    if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  icon,
                  color: textColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            margin: const EdgeInsets.all(AppSpacing.lg),
            duration: duration,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: textColor.withOpacity(0.8),
              onPressed: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              },
            ),
          ),
        );
      } catch (e) {
        // If there's an error showing the snackbar, we can silently ignore it
        // or optionally log it in debug mode
        debugPrint('Failed to show snackbar: $e');
      }
    }
  }
  
  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.success);
  }
  
  static void showError(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.error);
  }
  
  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.warning);
  }
  
  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.info);
  }

  // Aliases for compatibility
  static void success(BuildContext context, String message) => showSuccess(context, message);
  static void error(BuildContext context, String message) => showError(context, message);
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}
