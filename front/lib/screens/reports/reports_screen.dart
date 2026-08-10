import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/reports_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/waste_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/active_business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../models/business.dart';
import '../../providers/ai_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cashFlowSummaryAsync = ref.watch(cashFlowReportProvider);
    final groupBy = ref.watch(reportsGroupByProvider);
    final startDate = ref.watch(reportsStartDateProvider);
    final endDate = ref.watch(reportsEndDateProvider);
    final todayProfitAsync = ref.watch(todayDailyProfitProvider);
    final activeBusiness = ref.watch(activeBusinessProvider);
    final isManufacturing =
        activeBusiness?.businessType == BusinessType.manufacturing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cashFlowReportProvider);
          ref.invalidate(monthlyWasteLossProvider);
          ref.invalidate(totalExpensesProvider);
          ref.invalidate(todayDailyProfitProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters Card
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Report Settings',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: groupBy,
                                decoration: const InputDecoration(labelText: 'Group By'),
                                items: const [
                                  DropdownMenuItem(value: 'day', child: Text('Day')),
                                  DropdownMenuItem(value: 'week', child: Text('Week')),
                                  DropdownMenuItem(value: 'month', child: Text('Month')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(reportsGroupByProvider.notifier).state = val;
                                    // Auto-adjust date range to match the new groupBy
                                    final now = DateTime.now();
                                    switch (val) {
                                      case 'day':
                                        ref.read(reportsStartDateProvider.notifier).state =
                                            DateTime(now.year, now.month, now.day);
                                        ref.read(reportsEndDateProvider.notifier).state =
                                            DateTime(now.year, now.month, now.day, 23, 59, 59);
                                      case 'week':
                                        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                                        final endOfWeek = now.add(Duration(days: 7 - now.weekday));
                                        ref.read(reportsStartDateProvider.notifier).state =
                                            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                                        ref.read(reportsEndDateProvider.notifier).state =
                                            DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
                                      case 'month':
                                      default:
                                        ref.read(reportsStartDateProvider.notifier).state =
                                            DateTime(now.year, now.month, 1);
                                        ref.read(reportsEndDateProvider.notifier).state =
                                            DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final range = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 1)),
                                    initialDateRange: startDate != null && endDate != null
                                        ? DateTimeRange(start: startDate, end: endDate)
                                        : null,
                                  );
                                  if (range != null) {
                                    ref.read(reportsStartDateProvider.notifier).state = range.start;
                                    ref.read(reportsEndDateProvider.notifier).state = range.end;
                                  }
                                },
                                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                                label: Text(
                                  startDate == null
                                      ? 'Pick Date Range'
                                      : '${Formatters.date(startDate!)} - ${endDate == null ? Formatters.date(DateTime.now()) : Formatters.date(endDate!)}',
                                  style: AppTypography.labelSmall,
                                ),
                              ),
                            ),
                            if (startDate != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Reset to default range',
                                onPressed: () {
                                  // Reset to the groupBy-appropriate default range
                                  final now = DateTime.now();
                                  switch (groupBy) {
                                    case 'day':
                                      ref.read(reportsStartDateProvider.notifier).state =
                                          DateTime(now.year, now.month, now.day);
                                      ref.read(reportsEndDateProvider.notifier).state =
                                          DateTime(now.year, now.month, now.day, 23, 59, 59);
                                    case 'week':
                                      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                                      final endOfWeek = now.add(Duration(days: 7 - now.weekday));
                                      ref.read(reportsStartDateProvider.notifier).state =
                                          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                                      ref.read(reportsEndDateProvider.notifier).state =
                                          DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
                                    case 'month':
                                    default:
                                      ref.read(reportsStartDateProvider.notifier).state =
                                          DateTime(now.year, now.month, 1);
                                      ref.read(reportsEndDateProvider.notifier).state =
                                          DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              cashFlowSummaryAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(cashFlowReportProvider),
                ),
                data: (summary) {
                  final list = summary.periods;
                  final hasData = list.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Charts Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash Flow Chart',
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                if (!hasData)
                                  const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Text('No cash flow records for this period.'),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 220,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: true),
                                        titlesData: const FlTitlesData(
                                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: list.asMap().entries.map((e) {
                                              return FlSpot(e.key.toDouble(), e.value.cashIn);
                                            }).toList(),
                                            isCurved: true,
                                            color: isDark ? AppColors.successDark : AppColors.successLight,
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: (isDark ? AppColors.successDark : AppColors.successLight).withOpacity(0.1),
                                            ),
                                          ),
                                          LineChartBarData(
                                            spots: list.asMap().entries.map((e) {
                                              return FlSpot(e.key.toDouble(), e.value.cashOut);
                                            }).toList(),
                                            isCurved: true,
                                            color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: (isDark ? AppColors.dangerDark : AppColors.dangerLight).withOpacity(0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.md),
                                // Legend
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _LegendIndicator(
                                      color: isDark ? AppColors.successDark : AppColors.successLight,
                                      text: 'Cash In (Sales)',
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    _LegendIndicator(
                                      color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
                                      text: 'Cash Out (Expenses/Costs)',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Metrics Cards
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text('Summary Metrics', style: AppTypography.h4),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.45,
                        ),
                        children: [
                          StatCard(
                            title: 'Total Inflow',
                            value: Formatters.currency(summary.totalCashIn),
                            icon: Icons.arrow_downward,
                            color: isDark ? AppColors.successDark : AppColors.successLight,
                          ),
                          StatCard(
                            title: 'Total Outflow',
                            value: Formatters.currency(summary.totalCashOut),
                            icon: Icons.arrow_upward,
                            color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
                          ),
                          StatCard(
                            title: 'Net Cash Flow',
                            value: Formatters.currency(summary.netCashFlow),
                            icon: Icons.trending_up,
                            color: summary.netCashFlow >= 0
                                ? (isDark ? AppColors.successDark : AppColors.successLight)
                                : (isDark ? AppColors.dangerDark : AppColors.dangerLight),
                          ),
                          StatCard(
                            title: 'Non-Cash Losses',
                            value: Formatters.currency(summary.nonCashLosses),
                            icon: Icons.delete_outline,
                            color: isDark ? AppColors.warningDark : AppColors.warningLight,
                          ),
                        ],
                      ),

                      // Daily Profit & Loss Section
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text('Today\'s Profit & Loss', style: AppTypography.h4),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: todayProfitAsync.when(
                          loading: () => const LoadingShimmerList(
                              itemCount: 1),
                          error: (e, _) => Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Text('Could not load profit data: $e',
                                style: TextStyle(
                                    color: theme.colorScheme.error)),
                          ),
                          data: (profit) => Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Source label
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    isManufacturing
                                        ? 'Manufacturing — Menu Item Sales'
                                        : 'Resale — Product Sales',
                                    style: AppTypography.labelSmall.copyWith(
                                        color: theme.colorScheme.primary),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _ProfitRow(
                                  label: 'Total Revenue',
                                  value: Formatters.currency(profit.totalRevenue),
                                  color: isDark
                                      ? AppColors.successDark
                                      : AppColors.successLight,
                                ),
                                const Divider(),
                                _ProfitRow(
                                  label: 'Total Expenses',
                                  value: '− ${Formatters.currency(profit.totalExpenses)}',
                                  color: isDark
                                      ? AppColors.dangerDark
                                      : AppColors.dangerLight,
                                ),
                                const Divider(),
                                _ProfitRow(
                                  label: isManufacturing
                                      ? 'Net Profit (est.)'
                                      : 'Net Profit',
                                  value: Formatters.currency(profit.netProfit),
                                  color: profit.netProfit >= 0
                                      ? (isDark
                                          ? AppColors.successDark
                                          : AppColors.successLight)
                                      : (isDark
                                          ? AppColors.dangerDark
                                          : AppColors.dangerLight),
                                  bold: true,
                                ),
                                if (isManufacturing) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Includes revenue only — raw material costs per item are not tracked.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  );
                },
              ),

              // ─── AI Pricing & Sales Advice ────────────────────────────────
              const _AiPricingAdviceSection(),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfitRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _ProfitRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.bold)
        : AppTypography.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: style.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8))),
          Text(value, style: style.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendIndicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.labelSmall),
      ],
    );
  }
}

// ─── AI Pricing & Sales Advice Section ────────────────────────────────────────
class _AiPricingAdviceSection extends ConsumerWidget {
  const _AiPricingAdviceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pricingAsync = ref.watch(aiPricingAdviceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight)
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(Icons.auto_awesome,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('نصائح الأسعار والمبيعات',
                  style: AppTypography.h4),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        pricingAsync.when(
          loading: () => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(
                  width: double.infinity,
                  height: 80,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                const SizedBox(height: AppSpacing.md),
                LoadingShimmer(
                  width: double.infinity,
                  height: 80,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Could not load pricing advice',
                      style: AppTypography.bodySmall
                          .copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(aiPricingAdviceProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (advice) {
            if (advice == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    'No pricing data available yet.',
                    style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.5)),
                  ),
                ),
              );
            }

            // If AI suggestions are unavailable, show raw data table
            if (advice.suggestionsUnavailable) {
              return _RawDataFallback(
                  rawData: advice.rawData, isDark: isDark);
            }

            // Show suggestion cards
            if (advice.suggestions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: isDark
                              ? AppColors.successDark
                              : AppColors.successLight,
                          size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'No pricing issues detected — your prices look healthy!',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Column(
                children: advice.suggestions.map((s) {
                  return _PricingSuggestionCard(
                      suggestion: s, isDark: isDark);
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PricingSuggestionCard extends StatelessWidget {
  final dynamic suggestion; // PricingSuggestion
  final bool isDark;

  const _PricingSuggestionCard({
    required this.suggestion,
    required this.isDark,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'pricing':
        return Icons.price_change_outlined;
      case 'slow_mover':
        return Icons.trending_down_outlined;
      case 'general':
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'pricing':
        return isDark ? AppColors.warningDark : AppColors.warningLight;
      case 'slow_mover':
        return isDark ? AppColors.dangerDark : AppColors.dangerLight;
      case 'general':
      default:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForType(suggestion.type as String);
    final icon = _iconForType(suggestion.type as String);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.itemName as String,
                          style: AppTypography.bodyMedium.copyWith(
                              fontWeight: AppTypography.semiBold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text(
                          (suggestion.type as String)
                              .replaceAll('_', ' '),
                          style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: AppTypography.semiBold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    suggestion.suggestion as String,
                    style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.75)),
                  ),
                  if (suggestion.currentMargin != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Current margin: ${(suggestion.currentMargin as double).toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fallback when AI suggestions are unavailable — shows a raw margin/velocity table
class _RawDataFallback extends StatelessWidget {
  final List rawData;
  final bool isDark;

  const _RawDataFallback({required this.rawData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infoColor = isDark ? AppColors.infoDark : AppColors.infoLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notice banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: infoColor.withOpacity(0.08),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: infoColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: infoColor, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'AI suggestions are temporarily unavailable. Showing raw margin & velocity data.',
                    style: AppTypography.bodySmall
                        .copyWith(color: infoColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Raw data list
          if (rawData.isEmpty)
            Text(
              'No product data available.',
              style: AppTypography.bodySmall.copyWith(
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.5)),
            )
          else
            ...rawData.map((item) {
              return Card(
                margin:
                    const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name as String,
                              style:
                                  AppTypography.bodySmall.copyWith(
                                fontWeight: AppTypography.semiBold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Price: ${Formatters.currency(item.sellingPrice as double)}',
                              style:
                                  AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            Text(
                              item.marginPct != null
                                  ? '${(item.marginPct as double).toStringAsFixed(1)}%'
                                  : 'N/A',
                              style:
                                  AppTypography.bodySmall.copyWith(
                                fontWeight: AppTypography.semiBold,
                                color: (item.marginPct != null &&
                                        (item.marginPct
                                                as double) >=
                                            20)
                                    ? (isDark
                                        ? AppColors.successDark
                                        : AppColors.successLight)
                                    : (isDark
                                        ? AppColors.dangerDark
                                        : AppColors.dangerLight),
                              ),
                            ),
                            Text('margin',
                                style: AppTypography.labelSmall
                                    .copyWith(
                                        color: theme
                                            .colorScheme.onSurface
                                            .withOpacity(0.4))),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${item.unitsSold30d}',
                              style:
                                  AppTypography.bodySmall.copyWith(
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                            Text('units/30d',
                                style: AppTypography.labelSmall
                                    .copyWith(
                                        color: theme
                                            .colorScheme.onSurface
                                            .withOpacity(0.4))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
