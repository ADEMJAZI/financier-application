import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';

/// Status badge for CustomerDebt status: unpaid / partial / paid
class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'paid':
        bgColor =
            (isDark ? AppColors.successDark : AppColors.successLight).withOpacity(0.12);
        textColor = isDark ? AppColors.successDark : AppColors.successLight;
        label = 'Paid';
        icon = Icons.check_circle_outline;
        break;
      case 'partial':
        bgColor =
            (isDark ? AppColors.warningDark : AppColors.warningLight).withOpacity(0.12);
        textColor = isDark ? AppColors.warningDark : AppColors.warningLight;
        label = 'Partial';
        icon = Icons.timelapse_outlined;
        break;
      case 'unpaid':
      default:
        bgColor =
            (isDark ? AppColors.dangerDark : AppColors.dangerLight).withOpacity(0.12);
        textColor = isDark ? AppColors.dangerDark : AppColors.dangerLight;
        label = 'Unpaid';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpacing.sm : AppSpacing.md,
        vertical: small ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: (small ? AppTypography.labelSmall : AppTypography.labelMedium)
                .copyWith(color: textColor, fontWeight: AppTypography.semiBold),
          ),
        ],
      ),
    );
  }
}
