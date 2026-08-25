import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../models/business.dart';
import '../../models/menu_item.dart';
import '../../models/cart.dart';
import '../../models/order.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/order_providers.dart';
import '../../providers/order_cart_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/active_business_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/fade_in_up.dart';
import '../../widgets/bouncy_tap_widget.dart';
import '../../widgets/animated_count.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/sale_provider.dart';

/// Manufacturing mode: POS ordering with cart and glassmorphism checkout bar.
class ManufacturingSalesView extends ConsumerWidget {
  final Business business;

  const ManufacturingSalesView({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final todayOrdersAsync = ref.watch(activeBusinessDailySummaryProvider);
    final cart = ref.watch(orderCartProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Sales — Menu',
          style: AppTypography.h3.copyWith(
            fontFamily: AppTypography.fontFamily,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            onPressed: () => context.push('/order-history'),
            tooltip: AppLocalizations.of(context)!.orderHistory,
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            onPressed: () => context.push('/menu-items'),
            tooltip: AppLocalizations.of(context)!.manageMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Today's Revenue Summary Bar ──────────────────────────────
              todayOrdersAsync.when(
                loading: () => const _SummaryBarShimmer(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => _RevenueSummaryBar(
                  revenue: summary?.totalRevenue ?? 0,
                  orderCount: summary?.orderCount ?? 0,
                  isDark: isDark,
                ),
              ),

              // ── Menu Item Grid ───────────────────────────────────────────
              Expanded(
                child: menuItemsAsync.when(
                  loading: () => const LoadingShimmerList(),
                  error: (error, _) => ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.refresh(menuItemsProvider),
                  ),
                  data: (menuItems) {
                    if (menuItems.isEmpty) {
                      return EmptyState(
                        icon: Icons.restaurant_menu_rounded,
                        title: AppLocalizations.of(context)!.noMenuItemsYet,
                        message: AppLocalizations.of(context)!.addMenuItemsToStart,
                        actionLabel: AppLocalizations.of(context)!.manageMenu,
                        onAction: () => context.push('/menu-items'),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(menuItemsProvider);
                        ref.invalidate(activeBusinessDailySummaryProvider);
                      },
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cols = _gridColumns(constraints.maxWidth);
                          final aspectRatio = cols == 1 ? 2.5 : 1.05;
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              // Extra bottom padding so last row isn't hidden behind cart bar
                              cart.isNotEmpty ? 96 : AppSpacing.lg,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: menuItems.length,
                            itemBuilder: (ctx, i) {
                              final item = menuItems[i];
                              final qty = ref
                                  .watch(orderCartProvider.notifier)
                                  .getItemQuantity(item.id);
                              return FadeInUp(
                                delay: Duration(milliseconds: i * 50),
                                child: BouncyTapWidget(
                                  onPressed: () => ref
                                      .read(orderCartProvider.notifier)
                                      .addItem(item),
                                  child: _MenuItemCard(
                                    menuItem: item,
                                    quantity: qty,
                                    isDark: isDark,
                                    onAdd: () => ref
                                        .read(orderCartProvider.notifier)
                                        .addItem(item),
                                    onRemove: () => ref
                                        .read(orderCartProvider.notifier)
                                        .decrementItem(item.id),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ── Glassmorphism Cart Bar (floats above grid) ─────────────────
          if (cart.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _GlassCartBar(cart: cart, isDark: isDark),
            ),
        ],
      ),
    );
  }

  static int _gridColumns(double width) {
    if (width >= AppSpacing.breakpointExpanded) return 5;
    if (width >= AppSpacing.breakpointMedium) return 4;
    if (width >= AppSpacing.breakpointCompact) return 3;
    if (width >= 400) return 2;
    return 1;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Revenue summary bar at the top of the POS screen
class _RevenueSummaryBar extends StatelessWidget {
  final double revenue;
  final int orderCount;
  final bool isDark;

  const _RevenueSummaryBar({
    required this.revenue,
    required this.orderCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            primary.withOpacity(isDark ? 0.15 : 0.10),
            primary.withOpacity(isDark ? 0.05 : 0.03),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Revenue
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.iconContainerGradient(primary, isDark: isDark),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(LucideIcons.trendingUp, color: primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.todaysRevenue,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    AnimatedCount(
                      value: revenue,
                      formatter: Formatters.currency,
                      style: AppTypography.h3.copyWith(
                        fontFamily: AppTypography.numberFontFamily,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Order count badge
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.iconContainerGradient(primary, isDark: isDark),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: primary.withOpacity(0.25)),
            ),
            child: Text(
              '$orderCount ${AppLocalizations.of(context)!.todaysOrders}',
              style: AppTypography.labelMedium.copyWith(
                color: primary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for the summary bar
class _SummaryBarShimmer extends StatelessWidget {
  const _SummaryBarShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Center(child: LinearProgressIndicator()),
    );
  }
}

/// A single menu-item POS card with tap-to-add, quantity badge, and +/- controls
class _MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final int quantity;
  final bool isDark;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuItemCard({
    required this.menuItem,
    required this.quantity,
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final hasQty = quantity > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: hasQty ? primary.withOpacity(0.5) : border,
              width: hasQty ? 1.5 : 1,
            ),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                primary.withOpacity(isDark ? 0.08 : 0.04),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Icon + Quantity Badge ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Item category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.iconContainerGradient(primary, isDark: isDark),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      _getMenuItemIcon(menuItem.name),
                      color: primary,
                      size: 22,
                    ),
                  ),
                  // Quantity badge
                  if (hasQty)
                    Container(
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          quantity.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTypography.numberFontFamily,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── Name ──
              Text(
                menuItem.name,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.semiBold,
                  color: textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Subtitle (recipe count) ──
              if (menuItem.recipe.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${menuItem.recipe.length} ingredients',
                  style: AppTypography.bodySmall.copyWith(color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Spacer(),

              // ── Price + Add button ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Price
                  Flexible(
                    child: Text(
                      Formatters.currency(menuItem.sellingPrice),
                      style: AppTypography.currencySmall.copyWith(
                        color: primary,
                        fontFamily: AppTypography.numberFontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // +/- controls or add button
                  if (hasQty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleIconButton(
                          icon: Icons.remove,
                          size: 32,
                          color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
                          onTap: onRemove,
                        ),
                        const SizedBox(width: 4),
                        _CircleIconButton(
                          icon: Icons.add,
                          size: 32,
                          color: primary,
                          filled: true,
                          onTap: onAdd,
                        ),
                      ],
                    )
                  else
                    _CircleIconButton(
                      icon: Icons.add,
                      size: AppSpacing.minTouchTarget,
                      color: primary,
                      onTap: onAdd,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMenuItemIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('burger') || n.contains('sandwich') || n.contains('برغر')) {
      return LucideIcons.beef;
    }
    if (n.contains('pizza') || n.contains('بيتزا')) return LucideIcons.pizza;
    if (n.contains('coffee') || n.contains('قهوة')) return LucideIcons.coffee;
    if (n.contains('tea') || n.contains('شاي')) return LucideIcons.cupSoda;
    if (n.contains('salad') || n.contains('سلطة')) return LucideIcons.salad;
    if (n.contains('soup') || n.contains('شوربة')) return LucideIcons.soup;
    if (n.contains('chicken') || n.contains('دجاج')) return LucideIcons.drumstick;
    if (n.contains('meat') || n.contains('لحم')) return LucideIcons.beef;
    if (n.contains('fish') || n.contains('سمك')) return LucideIcons.fish;
    if (n.contains('pasta') || n.contains('معكرونة')) return LucideIcons.wheat;
    if (n.contains('dessert') || n.contains('cake') || n.contains('حلوى')) return LucideIcons.cake;
    if (n.contains('juice') || n.contains('عصير')) return LucideIcons.glassWater;
    if (n.contains('drink') || n.contains('مشروب')) return LucideIcons.cupSoda;
    if (n.contains('bread') || n.contains('خبز')) return LucideIcons.croissant;
    if (n.contains('شاورما')) return LucideIcons.utensils;
    if (n.contains('rice') || n.contains('أرز')) return LucideIcons.utensils;
    return LucideIcons.utensils;
  }
}

/// Small circular icon button used for +/- controls in the POS cards
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.size,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: filled ? color : color.withOpacity(0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: filled ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism cart summary bar that floats at the bottom of the POS screen
class _GlassCartBar extends ConsumerStatefulWidget {
  final Cart cart;
  final bool isDark;

  const _GlassCartBar({required this.cart, required this.isDark});

  @override
  ConsumerState<_GlassCartBar> createState() => _GlassCartBarState();
}

class _GlassCartBarState extends ConsumerState<_GlassCartBar> {
  bool _isCheckingOut = false;

  @override
  Widget build(BuildContext context) {
    final glass = widget.isDark ? AppColors.glassDark : AppColors.glassLight;
    final border = widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
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
              color: glass,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Checkout button — gradient
                  SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: _isCheckingOut
                        ? Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            height: AppSpacing.minTouchTarget,
                            decoration: BoxDecoration(
                              gradient: AppColors.fabGradient,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _checkout(context, ref),
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              height: AppSpacing.minTouchTarget,
                              decoration: BoxDecoration(
                                gradient: AppColors.fabGradient,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                boxShadow: AppColors.fabGlow(),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_cart_checkout,
                                      size: 20, color: Colors.white),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    AppLocalizations.of(context)!.checkout,
                                    style: AppTypography.button.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(width: AppSpacing.lg),

                  // Total + item count
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedCount(
                          value: widget.cart.totalAmount,
                          formatter: Formatters.currency,
                          style: AppTypography.h2.copyWith(
                            color: textPrimary,
                            fontWeight: AppTypography.bold,
                            fontFamily: AppTypography.numberFontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.cart.totalItems} ${AppLocalizations.of(context)!.items}',
                          style: AppTypography.bodySmall.copyWith(
                            color: textSecondary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
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

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    if (_isCheckingOut) return;

    setState(() { _isCheckingOut = true; });

    try {
      final orderService = ref.read(orderServiceProvider);
      final activeBusiness = ref.read(activeBusinessProvider);

      if (activeBusiness == null) {
        if (context.mounted) AppSnackbar.error(context, 'No business selected');
        return;
      }

      final order = await orderService
          .createOrder(activeBusiness.id, widget.cart.toOrderItems())
          .timeout(const Duration(seconds: 30));

      ref.read(orderCartProvider.notifier).clearCart();

      if (context.mounted) {
        // Invalidate ALL providers affected by stock/order changes
        ref.invalidate(activeBusinessDailySummaryProvider);
        ref.invalidate(activeBusinessOrdersProvider);
        ref.invalidate(productListProvider);
        ref.invalidate(reorderSuggestionsProvider);
        ref.invalidate(todayDailyProfitProvider);
        ref.invalidate(activeBusinessDailyProfitProvider);
        ref.invalidate(cashFlowReportProvider);
        // Also invalidate resale providers in case user switches business types
        ref.invalidate(todaySalesSummaryProvider);
        ref.invalidate(todayProfitReportProvider);
        await _showInvoiceDialog(context, order, activeBusiness);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to create order: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() { _isCheckingOut = false; });
      }
    }
  }

  Future<void> _showInvoiceDialog(
    BuildContext context,
    Order order,
    Business business,
  ) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Row(
                children: [
                  Icon(Icons.check_circle, color: primary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context)!.orderInvoice,
                    style: AppTypography.h3.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),

              const Divider(height: AppSpacing.xl),

              // ── Business + Invoice ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name,
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: AppTypography.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${order.invoiceLabel}  •  ${Formatters.dateTime(order.createdAt)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: AppTypography.numberFontFamily,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Items ──
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = order.items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}×',
                            style: AppTypography.labelLarge.copyWith(
                              color: primary,
                              fontFamily: AppTypography.numberFontFamily,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(item.name, style: AppTypography.bodyMedium),
                          ),
                          Text(
                            Formatters.currency(item.subtotal),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: AppTypography.semiBold,
                              fontFamily: AppTypography.numberFontFamily,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: AppSpacing.xl),

              // ── Total ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.total,
                      style: AppTypography.h4
                          .copyWith(fontWeight: AppTypography.bold)),
                  Text(
                    Formatters.currency(order.totalAmount),
                    style: AppTypography.currencyMedium.copyWith(
                      color: primary,
                      fontFamily: AppTypography.numberFontFamily,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Close button ──
              SizedBox(
                width: double.infinity,
                height: AppSpacing.minTouchTarget,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
