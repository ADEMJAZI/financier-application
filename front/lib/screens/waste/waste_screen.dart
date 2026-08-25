import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/waste_provider.dart';
import '../../models/waste.dart';
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

class WasteScreen extends ConsumerWidget {
  const WasteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wasteListAsync = ref.watch(wasteListProvider);
    final monthlyLoss = ref.watch(monthlyWasteLossProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Waste & Losses')),
      body: Column(
        children: [
          // Monthly Summary Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.dangerDark : AppColors.dangerLight).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: (isDark ? AppColors.dangerDark : AppColors.dangerLight).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: isDark ? AppColors.dangerDark : AppColors.dangerLight, size: 36),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Waste Loss',
                        style: AppTypography.labelMedium.copyWith(color: isDark ? AppColors.dangerDark : AppColors.dangerLight, fontWeight: AppTypography.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.currency(monthlyLoss),
                        style: AppTypography.h3.copyWith(color: isDark ? AppColors.dangerDark : AppColors.dangerLight, fontWeight: AppTypography.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Waste Entries List
          Expanded(
            child: wasteListAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(wasteListProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyState(
                    icon: Icons.delete_sweep_outlined,
                    title: 'No Waste Recorded',
                    message: 'Track spoiled, damaged, or lost inventory items here.',
                    actionLabel: 'Record Waste',
                    onAction: () => _showAddWasteSheet(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(wasteListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final entry = entries[i];
                      return _WasteCard(
                        entry: entry,
                        isDark: isDark,
                        onDelete: () => _deleteWaste(context, ref, entry),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          heroTag: null,
          icon: const Icon(Icons.add),
          label: const Text('Record Waste'),
          onPressed: () => _showAddWasteSheet(context, ref),
        ),
      ),
    );
  }

  void _showAddWasteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _AddWasteSheet(ref: ref),
    );
  }

  Future<void> _deleteWaste(BuildContext context, WidgetRef ref, Waste entry) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Waste Entry',
      message: 'This will remove the waste log for:',
      itemName: '${entry.quantity} ${entry.unit} of ${entry.productName}',
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(wasteNotifierProvider.notifier).deleteWaste(entry.id);
        ref.invalidate(wasteListProvider);
        if (context.mounted) AppSnackbar.success(context, 'Waste log removed');
      } catch (e) {
        if (context.mounted) AppSnackbar.error(context, e.toString());
      }
    }
  }
}

class _WasteCard extends StatelessWidget {
  final Waste entry;
  final bool isDark;
  final VoidCallback onDelete;

  const _WasteCard({required this.entry, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dangerColor = isDark ? AppColors.dangerDark : AppColors.dangerLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(Icons.delete_outline, color: dangerColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.productName,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          entry.reason,
                          style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        Formatters.quantityWithUnit(entry.quantity, entry.unit),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.date(entry.date),
                    style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(entry.estimatedLoss),
                  style: AppTypography.bodyMedium.copyWith(color: dangerColor, fontWeight: AppTypography.bold),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWasteSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddWasteSheet({required this.ref});

  @override
  ConsumerState<_AddWasteSheet> createState() => _AddWasteSheetState();
}

class _AddWasteSheetState extends ConsumerState<_AddWasteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _lossCtrl = TextEditingController();
  Product? _selectedProduct;
  String _selectedReason = WasteReason.all.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _lossCtrl.dispose();
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
              Text('Record Waste / Loss', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xl),

              // Product Picker Dropdown
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
                    // Auto estimate loss based on purchase price if quantity exists
                    _recalculateLoss();
                  }),
                  validator: (v) => v == null ? 'Please select a product' : null,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quantity
              TextFormField(
                controller: _quantityCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: const Icon(Icons.production_quantity_limits),
                  suffixText: _selectedProduct?.unit,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _recalculateLoss(),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Quantity'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reason
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                items: WasteReason.all.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r),
                )).toList(),
                onChanged: (v) => setState(() => _selectedReason = v!),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Estimated Loss
              TextFormField(
                controller: _lossCtrl,
                decoration: const InputDecoration(
                  labelText: 'Estimated Loss Value (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Estimated loss'),
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Record Waste',
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

  void _recalculateLoss() {
    final qty = double.tryParse(_quantityCtrl.text.replaceAll(',', '.')) ?? 0;
    if (_selectedProduct != null && qty > 0) {
      final loss = qty * _selectedProduct!.purchasePrice;
      _lossCtrl.text = loss.toStringAsFixed(3);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) return;
    setState(() => _isSubmitting = true);

    try {
      final businessId = widget.ref.read(activeBusinessIdProvider);
      if (businessId == null) throw Exception('No business selected');

      await widget.ref.read(wasteNotifierProvider.notifier).createWaste({
        'business': businessId,
        'product': _selectedProduct!.id,
        'productName': _selectedProduct!.name,
        'quantity': Validators.parseDouble(_quantityCtrl.text),
        'unit': _selectedProduct!.unit,
        'reason': _selectedReason,
        'estimatedLoss': Validators.parseDouble(_lossCtrl.text),
        'date': DateTime.now().toIso8601String(),
      });

      widget.ref.invalidate(wasteListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Waste logged successfully');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



