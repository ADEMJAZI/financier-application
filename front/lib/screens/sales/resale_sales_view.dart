import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/business.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_snackbar.dart';

/// Resale mode: Products with stock tracking, shows profit per sale
class ResaleSalesView extends ConsumerWidget {
  final Business business;

  const ResaleSalesView({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productListProvider);
    final todaySalesAsync = ref.watch(todaySalesSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sales),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/order-history'),
            tooltip: AppLocalizations.of(context)!.salesHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's Summary Bar
          todaySalesAsync.when(
            loading: () => const _SummaryBarShimmer(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Error loading summary: $e',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
            data: (summary) => _SummaryBar(
              title: 'Today\'s Revenue',
              value: Formatters.currency(summary.totalRevenue),
              subtitle: '${summary.saleCount} sales',
              color: AppColors.successLight,
            ),
          ),

          const Divider(height: 1),

          // Product List
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.refresh(productListProvider),
              ),
              data: (products) {
                final availableProducts = products.where((p) => p.quantity > 0).toList();

                if (availableProducts.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_outlined,
                    title: 'No Products Available',
                    message: 'Add products with stock to start recording sales.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(productListProvider);
                    ref.invalidate(todaySalesSummaryProvider);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate optimal grid layout
                      const itemMinWidth = 160.0;
                      final availableWidth = constraints.maxWidth - (AppSpacing.lg * 2);
                      final crossAxisCount = (availableWidth / itemMinWidth).floor().clamp(1, 4);
                      
                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: availableProducts.length,
                        itemBuilder: (context, index) {
                          final product = availableProducts[index];
                          return _ProductSaleCard(
                            product: product,
                            onSell: () => _recordSale(context, ref, product),
                            onQuickSell: () => _recordQuickSale(context, ref, product),
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
    );
  }

  Future<void> _recordQuickSale(BuildContext context, WidgetRef ref, Product product) async {
    try {
      await ref.read(saleNotifierProvider.notifier).recordSale(
            businessId: business.id,
            productId: product.id,
            quantity: 1,
          );

      if (context.mounted) {
        AppSnackbar.success(context, '1 ${product.name} sold');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<void> _recordSale(BuildContext context, WidgetRef ref, Product product) async {
    // Show quantity dialog
    final quantity = await _showQuantityDialog(context, product);
    if (quantity == null || quantity <= 0) return;

    try {
      await ref.read(saleNotifierProvider.notifier).recordSale(
            businessId: business.id,
            productId: product.id,
            quantity: quantity,
          );

      if (context.mounted) {
        AppSnackbar.success(context, 'Sale recorded successfully');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<double?> _showQuantityDialog(BuildContext context, Product product) async {
    final controller = TextEditingController(text: '1');
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sell ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available: ${product.quantity} ${product.unit}'),
              Text('Price: ${Formatters.currency(product.price)} per ${product.unit}'),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: product.unit,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text);
              Navigator.pop(ctx, qty);
            },
            child: const Text('Record Sale'),
          ),
        ],
      ),
    );
  }
}

class _ProductSaleCard extends StatelessWidget {
  final Product product;
  final VoidCallback onSell;
  final VoidCallback onQuickSell;

  const _ProductSaleCard({
    required this.product,
    required this.onSell,
    required this.onQuickSell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onSell,
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: AppTypography.semiBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Stock: ${product.quantity} ${product.unit}',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(product.price),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: AppTypography.semiBold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: theme.colorScheme.primary,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onQuickSell,
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

class _SummaryBar extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryBar({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.h3.copyWith(
                  color: color,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBarShimmer extends StatelessWidget {
  const _SummaryBarShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const LoadingShimmerList(itemCount: 1),
    );
  }
}
