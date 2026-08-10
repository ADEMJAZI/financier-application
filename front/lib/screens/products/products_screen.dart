import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../models/product.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredProductsAsync = ref.watch(filteredProductListProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Stock'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(productSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(productSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Product List
          Expanded(
            child: filteredProductsAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.refresh(productListProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  if (searchQuery.isNotEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: 'No Results',
                      message: 'No products found matching "$searchQuery"',
                      actionLabel: 'Clear Search',
                      onAction: () {
                        ref.read(productSearchQueryProvider.notifier).state = '';
                      },
                    );
                  }

                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Products Yet',
                    message: 'Add your first product to start tracking your inventory.',
                    actionLabel: 'Add Product',
                    onAction: () => _showAddProductBottomSheet(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(productListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductCard(
                        product: product,
                        isDark: isDark,
                        onTap: () => _showProductDetailsOptions(context, ref, product),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(heroTag: null,
        onPressed: () => _showAddProductBottomSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showAddProductBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _ProductFormSheet(ref: ref),
    );
  }

  void _showProductDetailsOptions(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(product.name, style: AppTypography.h4),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Restock Product'),
            onTap: () {
              Navigator.pop(ctx);
              _showRestockSheet(context, ref, product);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Details'),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                ),
                builder: (c) => _ProductFormSheet(ref: ref, product: product),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.dangerLight),
            title: const Text('Delete Product', style: TextStyle(color: AppColors.dangerLight)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await showConfirmationDialog(
                context,
                title: 'Delete Product',
                message: 'This will permanently remove the product:',
                itemName: product.name,
              );
              if (confirmed) {
                try {
                  await ref.read(productNotifierProvider.notifier).deleteProduct(product.id);
                  ref.invalidate(productListProvider);
                  if (context.mounted) AppSnackbar.success(context, 'Product deleted successfully');
                } catch (e) {
                  if (context.mounted) AppSnackbar.error(context, e.toString());
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _showRestockSheet(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _RestockSheet(product: product, ref: ref),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.isLowStock;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: AppTypography.semiBold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Unit: ${product.unit}',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.warningDark : AppColors.warningLight)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            size: 16,
                            color: isDark ? AppColors.warningDark : AppColors.warningLight,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Low Stock',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? AppColors.warningDark : AppColors.warningLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
              Divider(color: theme.dividerColor),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'Quantity',
                      value: Formatters.quantityWithUnit(product.quantity, product.unit),
                      valueColor: isLowStock
                          ? (isDark ? AppColors.warningDark : AppColors.warningLight)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      label: 'Purchase Price',
                      value: Formatters.currency(product.purchasePrice),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'Selling Price',
                      value: Formatters.currency(product.price),
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      label: 'Profit Margin',
                      value: Formatters.percentage(product.profitMargin),
                      valueColor: isDark ? AppColors.successDark : AppColors.successLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _DetailItem(
                label: 'Total Value',
                value: Formatters.currency(product.totalValue),
                valueColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: AppTypography.semiBold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Product? product;

  const _ProductFormSheet({required this.ref, this.product});

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _sellingPriceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _reorderPointCtrl;
  late final TextEditingController _reorderQtyCtrl;
  late String _selectedUnit;
  bool _isSubmitting = false;

  final List<String> _units = ['pcs', 'kg', 'litre', 'box', 'packet'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _purchasePriceCtrl = TextEditingController(text: p != null ? p.purchasePrice.toStringAsFixed(3) : '');
    _sellingPriceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(3) : '');
    _qtyCtrl = TextEditingController(text: p != null ? p.quantity.toString() : '');
    _reorderPointCtrl = TextEditingController(text: p != null ? p.reorderPoint.toString() : '5');
    _reorderQtyCtrl = TextEditingController(text: p != null ? p.reorderQuantity.toString() : '10');
    _selectedUnit = p?.unit ?? _units.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _qtyCtrl.dispose();
    _reorderPointCtrl.dispose();
    _reorderQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.product != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(isEdit ? 'Edit Product' : 'Add Product', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xl),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.label_outline)),
                validator: (v) => Validators.required(v, fieldName: 'Product name'),
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Unit of Measure', prefixIcon: Icon(Icons.scale_outlined)),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _selectedUnit = v!),
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceCtrl,
                      decoration: const InputDecoration(labelText: 'Purchase Price (DT)', prefixIcon: Icon(Icons.attach_money)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.positiveNumber(v, fieldName: 'Purchase price'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      decoration: const InputDecoration(labelText: 'Selling Price (DT)', prefixIcon: Icon(Icons.attach_money)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.positiveNumber(v, fieldName: 'Selling price'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!isEdit) ...[
                TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Initial Quantity', prefixIcon: Icon(Icons.production_quantity_limits)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.nonNegativeNumber(v, fieldName: 'Quantity'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _reorderPointCtrl,
                      decoration: const InputDecoration(labelText: 'Low Stock Level', prefixIcon: Icon(Icons.warning_amber_outlined)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.nonNegativeNumber(v, fieldName: 'Low stock level'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderQtyCtrl,
                      decoration: const InputDecoration(labelText: 'Auto-Reorder Qty', prefixIcon: Icon(Icons.shopping_cart_outlined)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.nonNegativeNumber(v, fieldName: 'Reorder quantity'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isEdit ? 'Update Details' : 'Add Product',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final businessId = widget.ref.read(activeBusinessIdProvider);
      if (businessId == null) throw Exception('No business selected');

      final data = {
        'business': businessId,
        'name': _nameCtrl.text.trim(),
        'unit': _selectedUnit,
        'purchasePrice': Validators.parseDouble(_purchasePriceCtrl.text),
        'price': Validators.parseDouble(_sellingPriceCtrl.text),
        'reorderPoint': Validators.parseDouble(_reorderPointCtrl.text),
        'reorderQuantity': Validators.parseDouble(_reorderQtyCtrl.text),
        if (widget.product == null) 'quantity': Validators.parseDouble(_qtyCtrl.text),
      };

      if (widget.product != null) {
        await widget.ref.read(productNotifierProvider.notifier).updateProduct(widget.product!.id, data);
      } else {
        await widget.ref.read(productNotifierProvider.notifier).createProduct(data);
      }

      widget.ref.invalidate(productListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, widget.product != null ? 'Product details updated' : 'Product added successfully');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Handle 409 Conflict: product already exists
        if (mounted) {
          Navigator.pop(context);
          _showDuplicateConflictDialog(context, _nameCtrl.text.trim());
        }
      } else {
        if (mounted) AppSnackbar.error(context, e.message ?? e.toString());
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showDuplicateConflictDialog(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Product Already Exists'),
        content: Text('A product named "$productName" already exists. Would you like to Restock it instead?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Lookup product and show restock sheet
              final products = widget.ref.read(productListProvider).valueOrNull ?? [];
              final match = products.firstWhere(
                (p) => p.name.toLowerCase() == productName.toLowerCase(),
                orElse: () => throw Exception('Product not found'),
              );
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                ),
                builder: (c) => _RestockSheet(product: match, ref: widget.ref),
              );
            },
            child: const Text('Restock Instead'),
          ),
        ],
      ),
    );
  }
}

class _RestockSheet extends ConsumerStatefulWidget {
  final Product product;
  final WidgetRef ref;

  const _RestockSheet({required this.product, required this.ref});

  @override
  ConsumerState<_RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends ConsumerState<_RestockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = widget.product.purchasePrice.toStringAsFixed(3);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Restock Product', style: AppTypography.h3),
              Text('Product: ${widget.product.name}', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.xl),

              TextFormField(
                controller: _qtyCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity to Add',
                  prefixIcon: const Icon(Icons.production_quantity_limits),
                  suffixText: widget.product.unit,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Quantity'),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'New Purchase Price (DT) (optional)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Record Restock',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final qty = Validators.parseDouble(_qtyCtrl.text);
      final price = _priceCtrl.text.isEmpty ? null : Validators.parseDouble(_priceCtrl.text);

      await widget.ref.read(productNotifierProvider.notifier).restockProduct(widget.product.id, qty, price);
      widget.ref.invalidate(productListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Stock restocked successfully');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



