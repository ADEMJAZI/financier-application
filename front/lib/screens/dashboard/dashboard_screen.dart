import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/order_providers.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/cash_register_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_snackbar.dart';
import '../../models/cash_register.dart';
import '../../models/business.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/ai_provider.dart';

// Handler for opening/closing cash register
void _handleCashRegister(
  BuildContext context,
  WidgetRef ref,
  CashRegister? register,
  bool isOpen,
) {
  if (isOpen && register != null) {
    // Close register
    _showCloseCashRegisterDialog(context, ref, register);
  } else {
    // Open register
    _showOpenCashRegisterDialog(context, ref);
  }
}

void _showOpenCashRegisterDialog(BuildContext context, WidgetRef ref) {
  final openingBalanceController = TextEditingController(text: '0');

  showDialog(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(context)!;
      // StatefulBuilder gives the dialog its own local state for the
      // submit guard — prevents double-taps from firing two open requests.
      bool submitting = false;

      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text(l10n.openCashRegister),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterOpeningBalance),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: openingBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.openingBalanceDT,
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      final openingBalance =
                          Validators.parseDouble(openingBalanceController.text);
                      Navigator.of(dialogContext).pop();
                      try {
                        final businessId = ref.read(activeBusinessIdProvider);
                        if (businessId == null) throw Exception('No business selected');
                        await ref.read(cashRegisterNotifierProvider.notifier).openRegister({
                          'business': businessId,
                          'openingBalance': openingBalance,
                        });
                        ref.invalidate(todayCashRegisterProvider);
                        if (context.mounted) {
                          AppSnackbar.success(context, l10n.cashRegisterOpenedSuccess);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final errorMsg = e.toString();
                          if (errorMsg.contains('already open')) {
                            AppSnackbar.error(context, l10n.registerAlreadyOpen);
                            ref.invalidate(todayCashRegisterProvider);
                          } else {
                            AppSnackbar.error(context, '${l10n.failedToOpenRegister}: $errorMsg');
                          }
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.openRegister),
            ),
          ],
        ),
      );
    },
  );
}

void _showCloseCashRegisterDialog(
  BuildContext context,
  WidgetRef ref,
  CashRegister register,
) {
  final closingBalanceController = TextEditingController(text: '0');

  showDialog(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(context)!;
      bool submitting = false;

      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text(l10n.closeCashRegister),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.openingBalance}: ${Formatters.currency(register.openingBalance)}',
                style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.enterActualCash),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: closingBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.closingBalanceDT,
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      final closingBalance =
                          Validators.parseDouble(closingBalanceController.text);
                      Navigator.of(dialogContext).pop();
                      try {
                        await ref
                            .read(cashRegisterNotifierProvider.notifier)
                            .closeRegister(register.id, closingBalance);
                        if (context.mounted) {
                          final discrepancy = closingBalance - register.openingBalance;
                          final message = discrepancy == 0
                              ? 'Cash register closed. ${l10n.noDiscrepancy}'
                              : 'Cash register closed. ${l10n.discrepancy}: ${Formatters.currency(discrepancy.abs())} ${discrepancy > 0 ? l10n.over : l10n.short}';
                          AppSnackbar.success(context, message);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackbar.error(context, '${l10n.failedToCloseRegister}: ${e.toString()}');
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.closeRegister),
            ),
          ],
        ),
      );
    },
  );
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    // Wait for authentication before loading any data
    final authAsync = ref.watch(authProvider);
    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Auth Error: $error'),
        ),
      ),
      data: (authState) {
        if (authState.status != AuthStatus.authenticated) {
          // This should not happen due to router redirects, but just in case
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Now safe to watch business data providers
        return _buildDashboard(context, ref, theme, isDark, l10n);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, ThemeData theme, bool isDark, AppLocalizations l10n) {
    final businessesAsync = ref.watch(businessListProvider);
    final selectedBusinessId = ref.watch(activeBusinessIdProvider);
    final activeBusiness = ref.watch(activeBusinessProvider);
    final productsAsync = ref.watch(productListProvider);
    final totalRemainingDebts = ref.watch(totalRemainingProvider);
    final todayRegisterAsync = ref.watch(todayCashRegisterProvider);
    final reorderSuggestionsAsync = ref.watch(reorderSuggestionsProvider);
    final cashFlowAsync = ref.watch(dashboardMonthlyCashFlowProvider);
    final todayProfitAsync = ref.watch(todayDailyProfitProvider);
    final isManufacturing = activeBusiness?.businessType == BusinessType.manufacturing;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.notificationsComingSoon)),
              );
            },
          ),
        ],
      ),
      body: businessesAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(businessListProvider),
        ),
        data: (businesses) {
          if (businesses.isEmpty) {
            return EmptyState(
              icon: Icons.business_outlined,
              title: l10n.noBusinessYet,
              message: l10n.createFirstBusiness,
              actionLabel: l10n.createBusiness,
              onAction: () {},
            );
          }

          if (selectedBusinessId == null && businesses.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(activeBusinessProvider.notifier).setActiveBusiness(businesses.first);
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(businessListProvider);
              ref.invalidate(productListProvider);
              ref.invalidate(debtListProvider);
              ref.invalidate(todayCashRegisterProvider);
              ref.invalidate(reorderSuggestionsProvider);
              ref.invalidate(dashboardMonthlyCashFlowProvider);
              ref.invalidate(cashFlowReportProvider);
              ref.invalidate(todayDailyProfitProvider);
              ref.invalidate(activeBusinessDailySummaryProvider);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final statColumns = width >= 800 ? 4 : (width >= 600 ? 3 : (width >= 400 ? 2 : 1));
                final statAspectRatio = width >= 800 ? 1.8 : (width >= 600 ? 1.6 : (width >= 400 ? 1.4 : 2.5));
                final isWide = width >= 800;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? AppColors.primaryMutedDark : AppColors.primaryMutedLight).withOpacity(0.05),
                        theme.scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                  child: CustomScrollView(
                  slivers: [
                    // Business Selector — compact card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Business icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Icon(
                                  isManufacturing
                                      ? Icons.restaurant
                                      : Icons.store,
                                  color: isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              // Dropdown
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedBusinessId,
                                    isExpanded: true,
                                    isDense: true,
                                    icon: const Icon(Icons.unfold_more, size: 18),
                                    items: businesses.map((business) {
                                      return DropdownMenuItem(
                                        value: business.id,
                                        child: Text(
                                          business.name,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            fontWeight: AppTypography.semiBold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        final selected = businesses
                                            .firstWhere((b) => b.id == value);
                                        ref
                                            .read(activeBusinessProvider.notifier)
                                            .setActiveBusiness(selected);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Cash Register Status Banner
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: todayRegisterAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => const SizedBox.shrink(),
                          data: (reg) {
                            final isOpen = reg != null && reg.isOpen;
                            return CashRegisterBanner(
                              isOpen: isOpen,
                              balanceFormatted: reg != null
                                  ? Formatters.currency(reg.openingBalance)
                                  : null,
                              onToggle: () => _handleCashRegister(
                                  context, ref, reg, isOpen),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.lg)),

                    // Section Header: Overview
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          l10n.overview,
                          style: AppTypography.h3.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.md)),

                    // Stats Grid — responsive columns
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      sliver: productsAsync.when(
                        loading: () => const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 120,
                            child:
                                Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (error, stack) => SliverToBoxAdapter(
                          child: ErrorState(
                            message: error.toString(),
                            onRetry: () =>
                                ref.refresh(productListProvider),
                          ),
                        ),
                        data: (products) {
                          final lowStockCount =
                              reorderSuggestionsAsync.valueOrNull?.length ??
                                  products
                                      .where((p) => p.isLowStock)
                                      .length;
                          final netCashFlow =
                              cashFlowAsync.valueOrNull?.netCashFlow ??
                                  0.0;

                          // Today's profit — branched by business type
                          final profitData =
                              todayProfitAsync.valueOrNull;
                          final todayNetProfit =
                              profitData?.netProfit ?? 0.0;
                          final profitLabel = isManufacturing
                              ? l10n.todaysRevenue
                              : l10n.todaysProfitLoss;

                          return SliverGrid(
                            delegate: SliverChildListDelegate([
                              StatCard(
                                title: profitLabel,
                                value: todayProfitAsync.isLoading
                                    ? '...'
                                    : Formatters.currency(todayNetProfit),
                                icon: isManufacturing
                                    ? Icons.storefront
                                    : Icons.account_balance_wallet_outlined,
                                color: todayNetProfit >= 0
                                    ? (isDark
                                        ? AppColors.successDark
                                        : AppColors.successLight)
                                    : (isDark
                                        ? AppColors.dangerDark
                                        : AppColors.dangerLight),
                              ),
                              StatCard(
                                title: l10n.activeProducts,
                                value: products.length.toString(),
                                icon: Icons.inventory_2_outlined,
                                color: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight,
                                useNumberFont: true,
                              ),
                              StatCard(
                                title: l10n.restockAlerts,
                                value: lowStockCount.toString(),
                                icon: Icons.warning_amber_outlined,
                                color: lowStockCount > 0
                                    ? (isDark
                                        ? AppColors.warningDark
                                        : AppColors.warningLight)
                                    : (isDark
                                        ? AppColors.successDark
                                        : AppColors.successLight),
                                useNumberFont: true,
                              ),
                              StatCard(
                                title: l10n.outstandingDebts,
                                value: Formatters.currency(
                                    totalRemainingDebts),
                                icon: Icons.money_off_outlined,
                                color: totalRemainingDebts > 0
                                    ? (isDark
                                        ? AppColors.dangerDark
                                        : AppColors.dangerLight)
                                    : (isDark
                                        ? AppColors.successDark
                                        : AppColors.successLight),
                              ),
                              StatCard(
                                title: l10n.monthlyCashFlow,
                                value:
                                    Formatters.currency(netCashFlow),
                                icon: Icons.auto_graph_outlined,
                                color: netCashFlow >= 0
                                    ? (isDark
                                        ? AppColors.successDark
                                        : AppColors.successLight)
                                    : (isDark
                                        ? AppColors.dangerDark
                                        : AppColors.dangerLight),
                              ),
                            ]),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: statColumns,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: statAspectRatio,
                            ),
                          );
                        },
                      ),
                    ),

                    // Today's Stock Usage (Manufacturing Only)
                    if (isManufacturing)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          child: _StockUsageCard(),
                        ),
                      ),

                    // ─── AI Anomaly Banner (compact, shown only if non-empty) ───
                    SliverToBoxAdapter(
                      child: _AiAnomalyBanner(),
                    ),

                    // ─── AI Smart Summary Card (ملخص ذكي) ─────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm),
                        child: _AiSummaryCard(),
                      ),
                    ),

                    // Quick Actions Section
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl)),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          l10n.quickActions,
                          style: AppTypography.h3.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.md)),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: _QuickActionsRow(isWide: isWide),
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxl)),
                  ],
                ),
              );
            },
            ),
          );
        },
      ),
    );
  }
}

/// Quick actions displayed as a row of icon buttons
class _QuickActionsRow extends StatelessWidget {
  final bool isWide;

  const _QuickActionsRow({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      _QuickAction(icon: Icons.point_of_sale,    label: l10n.sales,         onTap: () {}),
      _QuickAction(icon: Icons.receipt_long,     label: l10n.addExpense,    onTap: () {}),
      _QuickAction(icon: Icons.payments_outlined, label: l10n.debts,        onTap: () {}),
      _QuickAction(icon: Icons.assessment_outlined, label: l10n.reports,    onTap: () {}),
    ];

    if (isWide) {
      return Row(
        children: actions
            .map((a) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: ElevatedButton.icon(
                  icon: Icon(a.icon),
                  label: Text(a.label),
                  onPressed: a.onTap,
                ),
              )))
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final itemWidth = (availableWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: actions
              .map((a) => SizedBox(
                    width: itemWidth,
                    child: _QuickActionButton(
                      icon: a.icon,
                      label: a.label,
                      onTap: a.onTap,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                child: Icon(
                  icon,
                  size: 22,
                  color: primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockUsageCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(activeBusinessDailySummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary == null || summary.stockConsumed.isEmpty) {
          return const SizedBox.shrink(); // Hide if no stock consumed
        }

        return Card(
          margin: EdgeInsets.zero,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(Icons.inventory, color: theme.colorScheme.primary),
              title: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Text(
                    l10n.stockUsage,
                    style: AppTypography.bodyLarge.copyWith(fontWeight: AppTypography.semiBold),
                  );
                },
              ),
              childrenPadding: const EdgeInsets.all(AppSpacing.md).copyWith(top: 0),
              children: [
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                ...summary.stockConsumed.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.productName, style: AppTypography.bodyMedium),
                        Text(
                          '${Formatters.number(item.quantityConsumed)} ${item.unit ?? ''}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: AppTypography.semiBold,
                            fontFamily: AppTypography.numberFontFamily,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── AI Smart Summary Card (ملخص ذكي) ──────────────────────────────────────
class _AiSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final period = ref.watch(aiSummaryPeriodProvider);
    final summaryAsync = ref.watch(aiBusinessSummaryProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(Icons.auto_awesome,
                      color: primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('ملخص ذكي',
                      style: AppTypography.bodyLarge.copyWith(
                          fontWeight: AppTypography.semiBold)),
                ),
                // Week / Month toggle
                ToggleButtons(
                  isSelected: [period == 'week', period == 'month'],
                  onPressed: (i) {
                    ref.read(aiSummaryPeriodProvider.notifier).state =
                        i == 0 ? 'week' : 'month';
                  },
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  constraints: const BoxConstraints(
                      minWidth: 54, minHeight: 30),
                  textStyle: AppTypography.labelSmall,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text('أسبوع'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text('شهر'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Body
            summaryAsync.when(
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(
                    width: double.infinity,
                    height: 14,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LoadingShimmer(
                    width: 250,
                    height: 14,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LoadingShimmer(
                    width: 180,
                    height: 14,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ],
              ),
              error: (e, _) => Text(
                'Could not load summary',
                style: AppTypography.bodySmall
                    .copyWith(color: theme.colorScheme.error),
              ),
              data: (summary) {
                if (summary == null) {
                  return Text(
                    'No data available yet.',
                    style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.5)),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.summaryText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.85),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Compact metrics row
                    Row(
                      children: [
                        _MetricChip(
                          label: 'Revenue',
                          value: Formatters.currency(
                              summary.metrics.currentRevenue),
                          color: isDark
                              ? AppColors.successDark
                              : AppColors.successLight,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MetricChip(
                          label: 'Expenses',
                          value: Formatters.currency(
                              summary.metrics.currentExpenses),
                          color: isDark
                              ? AppColors.dangerDark
                              : AppColors.dangerLight,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MetricChip(
                          label: 'Profit',
                          value: Formatters.currency(
                              summary.metrics.currentProfit),
                          color: summary.metrics.currentProfit >= 0
                              ? (isDark
                                  ? AppColors.successDark
                                  : AppColors.successLight)
                              : (isDark
                                  ? AppColors.dangerDark
                                  : AppColors.dangerLight),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                    color: color.withOpacity(0.8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(value,
                style: AppTypography.labelSmall.copyWith(
                    color: color, fontWeight: AppTypography.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── AI Anomaly Banner (compact, shown only when anomalies exist) ────────────
class _AiAnomalyBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final anomaliesAsync = ref.watch(aiAnomaliesProvider);

    return anomaliesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (anomalies) {
        if (anomalies.isEmpty) return const SizedBox.shrink();

        final highCount =
            anomalies.where((a) => a.severity == 'high').length;
        final warningColor =
            isDark ? AppColors.warningDark : AppColors.warningLight;
        final dangerColor =
            isDark ? AppColors.dangerDark : AppColors.dangerLight;
        final bannerColor = highCount > 0 ? dangerColor : warningColor;

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Material(
            color: bannerColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () {
                // Show anomaly detail dialog
                _showAnomalyDialog(context, anomalies, isDark);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      highCount > 0
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: bannerColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${anomalies.length} anomal${anomalies.length == 1 ? 'y' : 'ies'} detected${highCount > 0 ? ' ($highCount critical)' : ''}',
                        style: AppTypography.bodySmall.copyWith(
                            color: bannerColor,
                            fontWeight: AppTypography.semiBold),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: bannerColor, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAnomalyDialog(
      BuildContext context, List anomalies, bool isDark) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded,
              color: isDark
                  ? AppColors.warningDark
                  : AppColors.warningLight,
              size: 22),
          const SizedBox(width: AppSpacing.sm),
          const Text('Anomalies Detected'),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: anomalies.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final a = anomalies[i];
              final severityColor = a.severity == 'high'
                  ? (isDark
                      ? AppColors.dangerDark
                      : AppColors.dangerLight)
                  : a.severity == 'medium'
                      ? (isDark
                          ? AppColors.warningDark
                          : AppColors.warningLight)
                      : (isDark
                          ? AppColors.infoDark
                          : AppColors.infoLight);
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(a.message,
                              style:
                                  AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            'Expected: ${Formatters.currency(a.expectedValue)} · Actual: ${Formatters.currency(a.value)}',
                            style: AppTypography.labelSmall
                                .copyWith(
                                    color: theme
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
