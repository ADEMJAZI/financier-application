import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Helper function to show modal bottom sheets with proper configuration
/// to prevent context issues and ensure multiple clicks work correctly
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent, // For custom border radius
    builder: (modalContext) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(modalContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: builder(modalContext),
      );
    },
  );
}
