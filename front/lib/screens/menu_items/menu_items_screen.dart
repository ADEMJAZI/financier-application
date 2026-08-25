import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/menu_item_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/gradient_fab.dart';
import '../../models/menu_item.dart';
import '../../models/product.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MenuItemsScreen extends ConsumerWidget {
  const MenuItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final menuItemsAsync = ref.watch(allMenuItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu Items'),
      ),
      body: menuItemsAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(allMenuItemsProvider),
        ),
        data: (menuItems) {
          if (menuItems.isEmpty) {
            return EmptyState(
              icon: Icons.restaurant_menu,
              title: 'No Menu Items Yet',
              message: 'Add your first menu item to start tracking sales for your manufacturing business.',
              actionLabel: 'Add Menu Item',
              onAction: () => _showAddMenuItemSheet(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allMenuItemsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final menuItem = menuItems[index];
                return _MenuItemCard(
                  menuItem: menuItem,
                  onTap: () => _showMenuItemOptions(context, ref, menuItem),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: GradientFAB(
          icon: LucideIcons.plus,
          label: 'Add Menu Item',
          onPressed: () => _showAddMenuItemSheet(context, ref),
        ),
      ),
    );
  }

  void _showAddMenuItemSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _MenuItemFormSheet(ref: ref),
    );
  }

  void _showMenuItemOptions(BuildContext context, WidgetRef ref, MenuItem menuItem) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(menuItem.name, style: AppTypography.h4),
          Text(
            menuItem.isActive ? 'Active' : 'Inactive',
            style: AppTypography.bodySmall.copyWith(
              color: menuItem.isActive ? AppColors.successLight : AppColors.textSecondaryLight,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.edit2),
            title: const Text('Edit Details'),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                ),
                builder: (c) => _MenuItemFormSheet(ref: ref, menuItem: menuItem),
              );
            },
          ),
          if (menuItem.isActive)
            ListTile(
              leading: const Icon(LucideIcons.archive, color: AppColors.warningLight),
              title: const Text('Deactivate', style: TextStyle(color: AppColors.warningLight)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Deactivate Menu Item',
                  message: 'This will hide the item from sales but preserve historical data:',
                  itemName: menuItem.name,
                );
                if (confirmed) {
                  try {
                    await ref.read(menuItemNotifierProvider.notifier).deactivateMenuItem(menuItem.id);
                    if (context.mounted) AppSnackbar.success(context, 'Menu item deactivated');
                  } catch (e) {
                    if (context.mounted) AppSnackbar.error(context, e.toString());
                  }
                }
              },
            )
          else
            ListTile(
              leading: const Icon(LucideIcons.packageOpen, color: AppColors.successLight),
              title: const Text('Activate', style: TextStyle(color: AppColors.successLight)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(menuItemNotifierProvider.notifier).updateMenuItem(
                        id: menuItem.id,
                        isActive: true,
                      );
                  if (context.mounted) AppSnackbar.success(context, 'Menu item activated');
                } catch (e) {
                  if (context.mounted) AppSnackbar.error(context, e.toString());
                }
              },
            ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: AppColors.dangerLight),
            title: const Text('Delete Permanently', style: TextStyle(color: AppColors.dangerLight)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await showConfirmationDialog(
                context,
                title: 'Delete Menu Item',
                message: 'This will permanently delete the item if it has no recorded sales:',
                itemName: menuItem.name,
              );
              if (confirmed) {
                try {
                  await ref.read(menuItemNotifierProvider.notifier).deleteMenuItem(menuItem.id);
                  if (context.mounted) AppSnackbar.success(context, 'Menu item deleted successfully');
                } catch (e) {
                  if (context.mounted) {
                    // Show user-friendly error for 400 (has sales)
                    final errorMessage = e.toString().contains('recorded sales')
                        ? 'Cannot delete: This item has recorded sales. Deactivate it instead.'
                        : e.toString();
                    AppSnackbar.error(context, errorMessage);
                  }
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.menuItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final isInactive = !menuItem.isActive;

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      isSelected: !isInactive,
      selectedAccentColor: primary,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: isInactive 
                    ? null 
                    : AppColors.iconContainerGradient(primary, isDark: isDark),
                color: isInactive ? theme.colorScheme.onSurface.withOpacity(0.05) : null,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                LucideIcons.utensils,
                color: isInactive ? theme.colorScheme.onSurface.withOpacity(0.3) : primary,
                size: 28,
              ),
            ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuItem.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: AppTypography.semiBold,
                        color: theme.colorScheme.onSurface.withOpacity(isInactive ? 0.5 : 1.0),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          Formatters.currency(menuItem.sellingPrice),
                          style: AppTypography.bodyLarge.copyWith(
                            color: theme.colorScheme.primary.withOpacity(isInactive ? 0.5 : 1.0),
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        if (menuItem.recipe.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              '${menuItem.recipe.length} ingredient${menuItem.recipe.length == 1 ? '' : 's'}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.infoLight,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.sm),
                        if (isInactive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'Inactive',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
    );
  }
}

class _MenuItemFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final MenuItem? menuItem;

  const _MenuItemFormSheet({required this.ref, this.menuItem});

  @override
  ConsumerState<_MenuItemFormSheet> createState() => _MenuItemFormSheetState();
}

class _MenuItemFormSheetState extends ConsumerState<_MenuItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  bool _isSubmitting = false;
  
  // Recipe management
  final List<_RecipeItem> _recipeItems = [];

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _priceCtrl = TextEditingController(text: item != null ? item.sellingPrice.toStringAsFixed(3) : '');
    
    // Initialize recipe items if editing
    if (item != null) {
      _recipeItems.addAll(
        item.recipe.map((ingredient) => _RecipeItem(
          rawMaterialId: ingredient.rawMaterialId,
          rawMaterialName: ingredient.rawMaterialName,
          unit: ingredient.unit,
          quantityRequired: ingredient.quantityRequired,
          currentStock: ingredient.currentStock,
        )),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.menuItem != null;

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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Edit Menu Item' : 'Add Menu Item',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Basic Info Section
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.label_outline),
                  hintText: 'e.g., Margherita Pizza',
                ),
                validator: (v) => Validators.required(v, fieldName: 'Item name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'e.g., 12.500',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Selling price'),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              
              // Recipe Section
              Row(
                children: [
                  Icon(Icons.restaurant, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Recipe & Ingredients', style: AppTypography.h4),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Optional: Define which raw materials are used to make this item',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Recipe Items List
              if (_recipeItems.isNotEmpty) ...[
                ...List.generate(_recipeItems.length, (index) {
                  final recipeItem = _recipeItems[index];
                  return _RecipeItemCard(
                    recipeItem: recipeItem,
                    onRemove: () {
                      setState(() {
                        _recipeItems.removeAt(index);
                      });
                    },
                    onQuantityChanged: (newQuantity) {
                      setState(() {
                        _recipeItems[index] = recipeItem.copyWith(quantityRequired: newQuantity);
                      });
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],
              
              // Add Ingredient Button
              OutlinedButton.icon(
                onPressed: () => _showAddIngredientSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isEdit ? 'Update Item' : 'Add Item',
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

  void _showAddIngredientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _AddIngredientSheet(
        onAdd: (ingredient) {
          setState(() {
            // Check if ingredient already exists
            final existingIndex = _recipeItems.indexWhere(
              (item) => item.rawMaterialId == ingredient.rawMaterialId,
            );
            if (existingIndex != -1) {
              // Update existing ingredient
              _recipeItems[existingIndex] = ingredient;
            } else {
              // Add new ingredient
              _recipeItems.add(ingredient);
            }
          });
        },
        excludeIds: _recipeItems.map((item) => item.rawMaterialId).toSet(),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final businessId = widget.ref.read(activeBusinessIdProvider);
      if (businessId == null) throw Exception('No business selected');

      final name = _nameCtrl.text.trim();
      final price = Validators.parseDouble(_priceCtrl.text);
      
      // Convert recipe items to API format
      final recipe = _recipeItems.map((item) => {
        'rawMaterial': item.rawMaterialId,
        'quantityRequired': item.quantityRequired,
      }).toList();

      if (widget.menuItem != null) {
        await widget.ref.read(menuItemNotifierProvider.notifier).updateMenuItem(
              id: widget.menuItem!.id,
              name: name,
              sellingPrice: price,
              recipe: recipe,
            );
      } else {
        await widget.ref.read(menuItemNotifierProvider.notifier).createMenuItem(
              businessId: businessId,
              name: name,
              sellingPrice: price,
              recipe: recipe,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(
          context,
          widget.menuItem != null ? 'Menu item updated' : 'Menu item added successfully',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        if (mounted) {
          AppSnackbar.error(
            context,
            'A menu item with this name already exists. Please choose a different name.',
          );
        }
      } else {
        if (mounted) AppSnackbar.error(context, e.message ?? e.toString());
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        AppSnackbar.error(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// Helper class for recipe items in the form
class _RecipeItem {
  final String rawMaterialId;
  final String rawMaterialName;
  final String unit;
  final double quantityRequired;
  final double currentStock;

  _RecipeItem({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.unit,
    required this.quantityRequired,
    required this.currentStock,
  });

  _RecipeItem copyWith({
    String? rawMaterialId,
    String? rawMaterialName,
    String? unit,
    double? quantityRequired,
    double? currentStock,
  }) {
    return _RecipeItem(
      rawMaterialId: rawMaterialId ?? this.rawMaterialId,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      unit: unit ?? this.unit,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      currentStock: currentStock ?? this.currentStock,
    );
  }
}

// Widget to display individual recipe items
class _RecipeItemCard extends StatefulWidget {
  final _RecipeItem recipeItem;
  final VoidCallback onRemove;
  final Function(double) onQuantityChanged;

  const _RecipeItemCard({
    required this.recipeItem,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  State<_RecipeItemCard> createState() => _RecipeItemCardState();
}

class _RecipeItemCardState extends State<_RecipeItemCard> {
  late TextEditingController _quantityCtrl;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
      text: widget.recipeItem.quantityRequired.toString(),
    );
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeItem = widget.recipeItem;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipeItem.rawMaterialName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        'Stock: ${recipeItem.currentStock} ${recipeItem.unit}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _quantityCtrl,
                decoration: InputDecoration(
                  labelText: recipeItem.unit,
                  isDense: true,
                  contentPadding: const EdgeInsets.all(AppSpacing.sm),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final quantity = double.tryParse(value);
                  if (quantity != null && quantity > 0) {
                    widget.onQuantityChanged(quantity);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close, color: AppColors.dangerLight),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// Sheet for adding new ingredients
class _AddIngredientSheet extends ConsumerStatefulWidget {
  final Function(_RecipeItem) onAdd;
  final Set<String> excludeIds;

  const _AddIngredientSheet({
    required this.onAdd,
    required this.excludeIds,
  });

  @override
  ConsumerState<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends ConsumerState<_AddIngredientSheet> {
  Product? _selectedProduct;
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Add Ingredient', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xl),
          
          // Product Search/Selection
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search Raw Materials',
              prefixIcon: Icon(Icons.search),
              hintText: 'Type to search...',
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Products List
          productsAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SizedBox(
              height: 100,
              child: Center(
                child: Text('Error loading products: $error'),
              ),
            ),
            data: (products) {
              // Filter products
              final filteredProducts = products.where((product) {
                if (widget.excludeIds.contains(product.id)) return false;
                if (_searchCtrl.text.isEmpty) return true;
                return product.name.toLowerCase().contains(_searchCtrl.text.toLowerCase());
              }).toList();

              if (filteredProducts.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('No raw materials found'),
                  ),
                );
              }

              return Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isSelected = _selectedProduct?.id == product.id;
                    
                    return ListTile(
                      selected: isSelected,
                      leading: Icon(
                        Icons.inventory_2_outlined,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(product.name),
                      subtitle: Text('${product.quantity} ${product.unit} available'),
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          
          if (_selectedProduct != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _quantityCtrl,
              decoration: InputDecoration(
                labelText: 'Required Quantity (${_selectedProduct!.unit})',
                prefixIcon: const Icon(Icons.scale),
                hintText: 'e.g., 2.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Add Ingredient',
                  onPressed: _selectedProduct == null ? null : _addIngredient,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  void _addIngredient() {
    if (_selectedProduct == null) return;
    
    final quantityText = _quantityCtrl.text.trim();
    if (quantityText.isEmpty) {
      AppSnackbar.error(context, 'Please enter a quantity');
      return;
    }
    
    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      AppSnackbar.error(context, 'Please enter a valid positive quantity');
      return;
    }

    final recipeItem = _RecipeItem(
      rawMaterialId: _selectedProduct!.id,
      rawMaterialName: _selectedProduct!.name,
      unit: _selectedProduct!.unit,
      quantityRequired: quantity,
      currentStock: _selectedProduct!.quantity,
    );

    widget.onAdd(recipeItem);
    Navigator.pop(context);
  }
}



