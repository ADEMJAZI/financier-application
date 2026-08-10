import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';

/// A reusable banner showing the cash register open/closed status.
class CashRegisterBanner extends StatelessWidget {
  final bool isOpen;
  final String? balanceFormatted;
  final String? subtitle;
  final VoidCallback onToggle;

  const CashRegisterBanner({
    super.key,
    required this.isOpen,
    this.balanceFormatted,
    this.subtitle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final color = isOpen
        ? (isDark ? AppColors.successDark : AppColors.successLight)
        : (isDark ? AppColors.dangerDark : AppColors.dangerLight);

    final defaultSubtitle = isOpen
        ? (balanceFormatted != null
            ? '${l10n.openingBalance}: $balanceFormatted'
            : l10n.cashRegisterOpen)
        : l10n.openDailyRegister;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        isOpen ? l10n.cashRegisterOpen : l10n.cashRegisterClosed,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: AppTypography.bold,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? defaultSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Toggle button
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              ),
              child: Text(
                isOpen ? l10n.close : l10n.open,
                style: AppTypography.button.copyWith(
                  color: color,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
