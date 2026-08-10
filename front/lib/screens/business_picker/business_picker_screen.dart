import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/business.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_snackbar.dart';

class BusinessPickerScreen extends ConsumerWidget {
  const BusinessPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final businessesAsync = ref.watch(businessListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Business'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: AppSpacing.md),
                    Text('Logout${user != null ? ' (${user.name})' : ''}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          businessesAsync.when(
            loading: () => const LoadingShimmerList(),
            error: (error, stack) => ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(businessListProvider),
            ),
            data: (businesses) {
              if (businesses.isEmpty) {
                return EmptyState(
                  icon: Icons.business_outlined,
                  title: 'Welcome to Business Manager',
                  message: 'Create your first business to start managing your inventory and finances.',
                  actionLabel: 'Create Your First Business',
                  onAction: () => _showCreateBusinessDialog(context, ref),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(businessListProvider);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null) ...[
                        Text(
                          'Hello, ${user.name}!',
                          style: AppTypography.h2.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Choose a business to manage:',
                          style: AppTypography.bodyLarge.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.lg,
                            mainAxisSpacing: AppSpacing.lg,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: businesses.length + 1, // +1 for add button
                          itemBuilder: (context, index) {
                            if (index == businesses.length) {
                              // Add new business tile
                              return _AddBusinessTile(
                                onTap: () => _showCreateBusinessDialog(context, ref),
                              );
                            }
                            
                            final business = businesses[index];
                            return _BusinessTile(
                              business: business,
                              onTap: () => _selectBusiness(context, ref, business),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _selectBusiness(BuildContext context, WidgetRef ref, Business business) async {
    await ref.read(activeBusinessProvider.notifier).setActiveBusiness(business);
    if (context.mounted) {
      context.go('/dashboard');
    }
  }

  void _showCreateBusinessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateBusinessDialog(ref: ref),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                AppSnackbar.success(context, 'Logged out successfully');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const _BusinessTile({
    required this.business,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  business.businessType.icon,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                business.name,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: AppTypography.semiBold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                business.businessType.displayName,
                style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBusinessTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBusinessTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5),
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.add,
                  size: 32,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add Business',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateBusinessDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _CreateBusinessDialog({required this.ref});

  @override
  ConsumerState<_CreateBusinessDialog> createState() => _CreateBusinessDialogState();
}

class _CreateBusinessDialogState extends ConsumerState<_CreateBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  BusinessType? _selectedType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Create New Business'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  hintText: 'e.g., My Restaurant',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Tunis, Tunisia',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of your business',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Business Type',
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This choice cannot be changed after creation',
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Business Type Selection
              ...BusinessType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          type.icon,
                          color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.displayName,
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: AppTypography.semiBold,
                                  color: isSelected 
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                type.description,
                                style: AppTypography.labelSmall.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _createBusiness,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Business'),
        ),
      ],
    );
  }

  Future<void> _createBusiness() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == null) {
      AppSnackbar.error(context, 'Please select a business type');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(businessServiceProvider).createBusiness(
        Business(
          id: '',
          name: _nameController.text.trim(),
          businessType: _selectedType!,
          type: 'business',
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Refresh the business list to get the new business
      ref.invalidate(businessListProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'Business created successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}