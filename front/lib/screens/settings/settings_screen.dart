import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/business_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/business.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../utils/validators.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _populateForm(Business business) {
    _nameCtrl.text = business.name;
    _typeCtrl.text = business.type;
    _locationCtrl.text = business.location;
    _descCtrl.text = business.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(selectedBusinessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Profile Section
            Text('Business Profile', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.md),
            businessAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading business: $e'),
              data: (business) {
                if (business == null) return const Text('No business selected');

                // Populate controller values if empty
                if (_nameCtrl.text.isEmpty && _typeCtrl.text.isEmpty) {
                  _populateForm(business);
                }

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Business Name'),
                            validator: (v) => Validators.required(v, fieldName: 'Business name'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _typeCtrl,
                            decoration: const InputDecoration(labelText: 'Business Type (e.g. Restaurant, Shop)'),
                            validator: (v) => Validators.required(v, fieldName: 'Business type'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _locationCtrl,
                            decoration: const InputDecoration(labelText: 'Location'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(labelText: 'Description'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: 'Save Profile Changes',
                            isLoading: _isSubmitting,
                            onPressed: () => _saveProfile(business.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('App Settings', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.md),

            // Light/Dark Theme Mock Toggle
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('Switch light/dark settings'),
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (v) {
                        AppSnackbar.showInfo(context, 'Theme switching uses system settings by default.');
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Language'),
                    subtitle: const Text('العربية / Français / English'),
                    onTap: () {
                      _showLanguageSelector(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('العربية (RTL)'), onTap: () => Navigator.pop(ctx)),
            ListTile(title: const Text('Français'), onTap: () => Navigator.pop(ctx)),
            ListTile(title: const Text('English'), onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(String businessId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(businessServiceProvider);
      final currentBusiness = ref.read(selectedBusinessProvider).value;
      if (currentBusiness == null) throw Exception('No business loaded');

      final updatedBusiness = currentBusiness.copyWith(
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );

      await service.updateBusiness(businessId, updatedBusiness);

      ref.invalidate(businessListProvider);
      ref.invalidate(selectedBusinessProvider);

      if (mounted) AppSnackbar.success(context, 'Profile updated successfully');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
