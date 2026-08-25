import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'premium_card.dart';

/// Enhanced stat card with trend indicator and compact mode.
/// Used on the dashboard for KPI display, now utilizing PremiumCard.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  
  /// Optional trend percentage (e.g., 12.5 for +12.5%, -5.2 for -5.2%)
  final double? trendPercent;
  
  /// Whether to use compact layout (smaller padding, no trend)
  final bool compact;

  /// Whether to use Inter/number font for the value
  final bool useNumberFont;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.trendPercent,
    this.compact = false,
    this.useNumberFont = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardPadding = compact ? AppSpacing.md : AppSpacing.lg;

    return PremiumCard(
      onTap: onTap,
      padding: EdgeInsets.zero, // We handle padding inside the gradient container
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusMd)),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              isDark ? color.withOpacity(0.15) : color.withOpacity(0.10),
              isDark ? color.withOpacity(0.03) : color.withOpacity(0.01),
            ],
          ),
        ),
        padding: EdgeInsetsDirectional.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient icon container
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.iconContainerGradient(color, isDark: isDark),
                    borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                if (onTap != null && trendPercent == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            // Title
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Value
            Text(
              value,
              style: (compact ? AppTypography.h3 : AppTypography.h2).copyWith(
                color: theme.colorScheme.onSurface,
                fontFamily: useNumberFont
                    ? AppTypography.numberFontFamily
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trendPercent != null && !compact) ...[
              const SizedBox(height: AppSpacing.md),
              _TrendBadge(
                percent: trendPercent!,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small badge showing trend direction and percentage
class _TrendBadge extends StatelessWidget {
  final double percent;
  final bool isDark;

  const _TrendBadge({
    required this.percent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percent >= 0;
    final color = isPositive
        ? (isDark ? AppColors.trendUpDark : AppColors.trendUpLight)
        : (isDark ? AppColors.trendDownDark : AppColors.trendDownLight);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusXs)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%',
            style: AppTypography.trend.copyWith(
              color: color,
              fontFamily: AppTypography.numberFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
