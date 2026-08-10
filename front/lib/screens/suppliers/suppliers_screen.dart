import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/supplier_provider.dart';
import '../../models/supplier.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../providers/business_provider.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: suppliersAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(supplierListProvider),
        ),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No Suppliers Yet',
              message: 'Add suppliers to track purchases and restock inventory.',
              actionLabel: 'Add Supplier',
              onAction: () => _showAddSupplierSheet(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supplierListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: suppliers.length,
              itemBuilder: (ctx, i) {
                final s = suppliers[i];
                return _SupplierCard(
                  supplier: s,
                  isDark: isDark,
                  onRecordPurchase: () => _showRecordPurchaseSheet(context, ref, s),
                  onDelete: () => _deleteSupplier(context, ref, s),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(heroTag: null,
        onPressed: () => _showAddSupplierSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }

  void _showAddSupplierSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _AddSupplierSheet(ref: ref),
    );
  }

  void _showRecordPurchaseSheet(BuildContext context, WidgetRef ref, Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _RecordPurchaseSheet(supplier: supplier, ref: ref),
    );
  }

  Future<void> _deleteSupplier(BuildContext context, WidgetRef ref, Supplier s) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Supplier',
      message: 'This will permanently delete the supplier:',
      itemName: s.name,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(supplierNotifierProvider.notifier).deleteSupplier(s.id);
        ref.invalidate(supplierListProvider);
        if (context.mounted) AppSnackbar.success(context, 'Supplier deleted');
      } catch (e) {
        if (context.mounted) AppSnackbar.error(context, e.toString());
      }
    }
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final bool isDark;
  final VoidCallback onRecordPurchase;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.isDark,
    required this.onRecordPurchase,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(Icons.local_shipping_outlined, color: primaryColor, size: 24),
        ),
        title: Text(supplier.name, style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.phone != null && supplier.phone!.isNotEmpty)
              Text('Phone: ${supplier.phone}', style: AppTypography.labelSmall),
            Text(
              'Total Purchased: ${Formatters.currency(supplier.totalPurchaseValue)}',
              style: AppTypography.labelSmall.copyWith(color: primaryColor, fontWeight: AppTypography.semiBold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              onPressed: onDelete,
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Record Purchase',
                  icon: Icons.add_shopping_cart,
                  onPressed: onRecordPurchase,
                ),
              ),
            ],
          ),
          if (supplier.purchases.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Purchase History',
                style: AppTypography.labelMedium.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: AppSpacing.sm),
            ...supplier.purchases.reversed.take(5).map((p) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '${p.productName} x ${Formatters.quantityWithUnit(p.quantity, p.unit)}',
                  style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.semiBold),
                ),
                subtitle: Text('Unit Price: ${Formatters.currency(p.unitPrice)}', style: AppTypography.labelSmall),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(Formatters.currency(p.total),
                        style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.bold)),
                    Text(Formatters.date(p.date), style: AppTypography.labelSmall),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AddSupplierSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddSupplierSheet({required this.ref});

  @override
  ConsumerState<_AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends ConsumerState<_AddSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
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
              Text('Add Supplier', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, fieldName: 'Supplier name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Save Supplier',
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

      await widget.ref.read(supplierNotifierProvider.notifier).createSupplier({
        'business': businessId,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      });

      widget.ref.invalidate(supplierListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Supplier saved successfully');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _RecordPurchaseSheet extends ConsumerStatefulWidget {
  final Supplier supplier;
  final WidgetRef ref;

  const _RecordPurchaseSheet({required this.supplier, required this.ref});

  @override
  ConsumerState<_RecordPurchaseSheet> createState() => _RecordPurchaseSheetState();
}

class _RecordPurchaseSheetState extends ConsumerState<_RecordPurchaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  Product? _selectedProduct;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = widget.ref.watch(productListProvider);

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
              Text('Record Purchase', style: AppTypography.h3),
              Text('Supplier: ${widget.supplier.name}', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.xl),

              // Product selection
              productsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading products: $e'),
                data: (products) => DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  hint: const Text('Select Product'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: products.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text('${p.name} (${p.unit})'),
                  )).toList(),
                  onChanged: (p) => setState(() {
                    _selectedProduct = p;
                    if (p != null) {
                      _priceCtrl.text = p.purchasePrice.toStringAsFixed(3);
                    }
                  }),
                  validator: (v) => v == null ? 'Please select a product' : null,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quantity
              TextFormField(
                controller: _qtyCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: const Icon(Icons.production_quantity_limits),
                  suffixText: _selectedProduct?.unit,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Quantity'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Unit Price
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit Price (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Unit price'),
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Record Purchase',
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
    if (_selectedProduct == null) return;
    setState(() => _isSubmitting = true);

    try {
      final qty = Validators.parseDouble(_qtyCtrl.text);
      final price = Validators.parseDouble(_priceCtrl.text);

      await widget.ref.read(supplierNotifierProvider.notifier).recordPurchase(
        widget.supplier.id,
        {
          'product': _selectedProduct!.id,
          'productName': _selectedProduct!.name,
          'quantity': qty,
          'unit': _selectedProduct!.unit,
          'unitPrice': price,
          'total': qty * price,
          'date': DateTime.now().toIso8601String(),
        },
      );

      // Invalidate products as quantity on hand and purchasePrice might have updated
      widget.ref.invalidate(productListProvider);
      widget.ref.invalidate(supplierListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Purchase recorded, stock updated');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



