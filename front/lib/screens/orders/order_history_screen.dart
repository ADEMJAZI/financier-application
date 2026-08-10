import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/business.dart';
import '../../models/order.dart';
import '../../models/sale.dart';
import '../../providers/active_business_provider.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';

/// Provider for orders history with date filtering
final ordersHistoryProvider = FutureProvider.family<List<Order>, OrderHistoryParams>(
  (ref, params) async {
    final orderService = ref.watch(orderServiceProvider);
    final orders = await orderService.getOrdersByBusiness(params.businessId);
    
    // Filter by date range
    return orders.where((order) {
      final orderDate = order.date;
      return orderDate.isAfter(params.startDate.subtract(const Duration(days: 1))) &&
             orderDate.isBefore(params.endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  },
);

/// Provider for sales history with date filtering
final salesHistoryProvider = FutureProvider.family<List<Sale>, OrderHistoryParams>(
  (ref, params) async {
    final saleService = ref.watch(saleServiceProvider);
    return saleService.getSalesByBusiness(
      params.businessId,
      from: params.startDate,
      to: params.endDate,
    );
  },
);

class OrderHistoryParams {
  final String businessId;
  final DateTime startDate;
  final DateTime endDate;

  OrderHistoryParams({
    required this.businessId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderHistoryParams &&
          businessId == other.businessId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(businessId, startDate, endDate);
}

/// Order/Sales History Screen — adapts to business type
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day - 30); // Last 30 days
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBusiness = ref.watch(activeBusinessProvider);

    if (activeBusiness == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const Center(child: Text('No business selected')),
      );
    }

    final isManufacturing = activeBusiness.businessType == BusinessType.manufacturing;
    final l10n = AppLocalizations.of(context)!;
    final params = OrderHistoryParams(
      businessId: activeBusiness.id,
      startDate: _startDate,
      endDate: _endDate,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          isManufacturing ? l10n.orderHistory : l10n.salesHistory,
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () => _showDateRangePicker(context),
            tooltip: l10n.filterByDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range indicator
          _DateRangeBar(
            startDate: _startDate,
            endDate: _endDate,
            isDark: isDark,
            onTap: () => _showDateRangePicker(context),
          ),

          // History list
          Expanded(
            child: isManufacturing
                ? _OrderHistoryList(params: params)
                : _SalesHistoryList(params: params),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }
}

/// Date range indicator bar
class _DateRangeBar extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool isDark;
  final VoidCallback onTap;

  const _DateRangeBar({
    required this.startDate,
    required this.endDate,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_rounded, color: primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${Formatters.date(startDate)} - ${Formatters.date(endDate)}',
              style: AppTypography.labelMedium.copyWith(
                color: textSecondary,
                fontFamily: AppTypography.numberFontFamily,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Order history list for manufacturing businesses
class _OrderHistoryList extends ConsumerWidget {
  final OrderHistoryParams params;

  const _OrderHistoryList({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersHistoryProvider(params));

    return ordersAsync.when(
      loading: () => const LoadingShimmerList(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(ordersHistoryProvider(params)),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_rounded,
            title: AppLocalizations.of(context)!.noOrdersFound,
            message: AppLocalizations.of(context)!.noOrdersInPeriod,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ordersHistoryProvider(params));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (ctx, i) => _OrderHistoryCard(order: orders[i]),
          ),
        );
      },
    );
  }
}

/// Sales history list for resale businesses
class _SalesHistoryList extends ConsumerWidget {
  final OrderHistoryParams params;

  const _SalesHistoryList({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider(params));

    return salesAsync.when(
      loading: () => const LoadingShimmerList(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(salesHistoryProvider(params)),
      ),
      data: (sales) {
        if (sales.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_rounded,
            title: AppLocalizations.of(context)!.noSalesFound,
            message: AppLocalizations.of(context)!.noSalesInPeriod,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(salesHistoryProvider(params));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (ctx, i) => _SaleHistoryCard(sale: sales[i]),
          ),
        );
      },
    );
  }
}

/// Order history card
class _OrderHistoryCard extends StatelessWidget {
  final Order order;

  const _OrderHistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Invoice + Status badge
              Row(
                children: [
                  // Invoice number
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      order.invoiceLabel,
                      style: AppTypography.labelMedium.copyWith(
                        color: primary,
                        fontWeight: AppTypography.semiBold,
                        fontFamily: AppTypography.numberFontFamily,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Status badge
                  if (order.isVoided)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.dangerDark : AppColors.dangerLight)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.voided,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Date/time
                  Text(
                    Formatters.dateTime(order.date),
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                      fontFamily: AppTypography.numberFontFamily,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Item count
              Text(
                '${order.items.length} ${AppLocalizations.of(context)!.item}',
                style: AppTypography.bodyMedium.copyWith(color: textSecondary),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Total amount — order card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.total,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textSecondary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    Formatters.currency(order.totalAmount),
                    style: AppTypography.currencySmall.copyWith(
                      color: order.isVoided
                          ? textSecondary
                          : primary,
                      fontFamily: AppTypography.numberFontFamily,
                      decoration: order.isVoided ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sale history card
class _SaleHistoryCard extends StatelessWidget {
  final Sale sale;

  const _SaleHistoryCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Product name + Date/time
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.productName ?? AppLocalizations.of(context)!.item,
                    style: AppTypography.bodyLarge.copyWith(
                      color: textPrimary,
                      fontWeight: AppTypography.semiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Formatters.dateTime(sale.date),
                  style: AppTypography.bodySmall.copyWith(
                    color: textSecondary,
                    fontFamily: AppTypography.numberFontFamily,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Quantity × Unit price
            Row(
              children: [
                Text(
                  '${Formatters.number(sale.quantity)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                    fontFamily: AppTypography.numberFontFamily,
                  ),
                ),
                Text(
                  ' × ',
                  style: AppTypography.bodyMedium.copyWith(color: textSecondary),
                ),
                Text(
                  Formatters.currency(sale.unitPrice),
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                    fontFamily: AppTypography.numberFontFamily,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.total,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                Text(
                  Formatters.currency(sale.totalAmount),
                  style: AppTypography.currencySmall.copyWith(
                    color: primary,
                    fontFamily: AppTypography.numberFontFamily,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
