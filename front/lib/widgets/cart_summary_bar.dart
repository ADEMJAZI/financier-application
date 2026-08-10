import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';

/// A glassmorphism floating bar that shows the current cart state
/// and a checkout CTA button. Appears at the bottom of the POS screen.
class CartSummaryBar extends StatelessWidget {
  final int itemCount;
  final String totalFormatted;
  final VoidCallback onCheckout;
  final VoidCallback? onViewCart;

  const CartSummaryBar({
    super.key,
    required this.itemCount,
    required this.totalFormatted,
    required this.onCheckout,
    this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassDark : AppColors.glassLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Checkout button
                  SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: ElevatedButton.icon(
                      onPressed: onCheckout,
                      icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.checkout,
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.lg),

                  // Total amount
                  Expanded(
                    child: GestureDetector(
                      onTap: onViewCart,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            totalFormatted,
                            style: AppTypography.currencyMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontFamily: AppTypography.numberFontFamily,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$itemCount ${AppLocalizations.of(context)!.items}',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
