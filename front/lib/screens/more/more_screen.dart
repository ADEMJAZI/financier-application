import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/active_business_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_snackbar.dart';
import '../../models/business.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final activeBusiness = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.more),
      ),
      body: ListView(
        children: [
          // User Profile Section
          if (user != null)
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: AppTypography.h3.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (activeBusiness != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  activeBusiness.name,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Account Actions
          _SectionHeader(title: l10n.account ?? 'Account'),
          _MenuTile(
            icon: Icons.swap_horiz,
            title: l10n.switchBusiness ?? 'Switch Business',
            subtitle: l10n.selectDifferentBusiness ?? 'Select a different business to manage',
            onTap: () {
              // Clear active business and navigate to business picker
              ref.read(activeBusinessProvider.notifier).clearActiveBusiness();
              context.go('/business-picker');
            },
          ),
          _MenuTile(
            icon: Icons.logout,
            title: l10n.logout ?? 'Logout',
            subtitle: l10n.signOutOfAccount ?? 'Sign out of your account',
            onTap: () {
              _showLogoutDialog(context, ref);
            },
          ),

          const Divider(),
          
          // Sales & Products Section
          _SectionHeader(title: activeBusiness?.businessType == BusinessType.manufacturing ? 'Sales & Menu' : 'Sales'),
          _MenuTile(
            icon: Icons.point_of_sale,
            title: 'Point of Sale',
            subtitle: 'Record a new sale or view today\'s orders',
            onTap: () {
              context.push('/sales');
            },
          ),
          _MenuTile(
            icon: Icons.history_rounded,
            title: activeBusiness?.businessType == BusinessType.manufacturing
                ? 'Order History'
                : 'Sales History',
            subtitle: activeBusiness?.businessType == BusinessType.manufacturing
                ? 'View all past orders and invoices'
                : 'View all past sales transactions',
            onTap: () {
              context.push('/order-history');
            },
          ),
          if (activeBusiness?.businessType == BusinessType.manufacturing)
            _MenuTile(
              icon: Icons.restaurant_menu,
              title: 'Menu Items',
              subtitle: 'Manage your menu and recipes',
              onTap: () {
                context.push('/menu-items');
              },
            ),

          const Divider(),
          // Business Management Section
          _SectionHeader(title: l10n.businessManagement),
          _MenuTile(
            icon: Icons.business,
            title: l10n.businessProfile,
            subtitle: l10n.viewEditBusiness,
            onTap: () {
              context.push('/settings');
            },
          ),
          _MenuTile(
            icon: Icons.local_shipping,
            title: l10n.suppliers,
            subtitle: l10n.manageSuppliers,
            onTap: () {
              context.push('/suppliers');
            },
          ),
          _MenuTile(
            icon: Icons.people,
            title: l10n.employees,
            subtitle: l10n.manageEmployees,
            onTap: () {
              context.push('/employees');
            },
          ),
          _MenuTile(
            icon: Icons.delete_outline,
            title: l10n.wasteAndLoss,
            subtitle: l10n.trackProductWaste,
            onTap: () {
              context.push('/waste');
            },
          ),

          const Divider(),

          // Financial Section
          _SectionHeader(title: l10n.financial),
          _MenuTile(
            icon: Icons.app_registration,
            title: l10n.cashRegister,
            subtitle: l10n.dailyCashManagement,
            onTap: () {
              context.push('/cash-register');
            },
          ),
          _MenuTile(
            icon: Icons.savings,
            title: l10n.reserveFunds,
            subtitle: l10n.manageSavingsFunds,
            onTap: () {
              context.push('/reserves');
            },
          ),
          _MenuTile(
            icon: Icons.assessment,
            title: l10n.reports,
            subtitle: l10n.viewFinancialReports,
            onTap: () {
              context.push('/reports');
            },
          ),

          const Divider(),

          // Inventory Section
          _SectionHeader(title: l10n.inventory),
          _MenuTile(
            icon: Icons.shopping_cart,
            title: l10n.reorderSuggestions,
            subtitle: l10n.productsNeedRestocking,
            onTap: () {
              context.push('/reorder');
            },
          ),
          _MenuTile(
            icon: Icons.history,
            title: l10n.auditLog,
            subtitle: l10n.viewAllChanges,
            onTap: () {
              context.push('/audit-log');
            },
          ),
          _MenuTile(
            icon: Icons.warning_amber_rounded,
            title: 'AI Anomaly Detection',
            subtitle: 'View spending & revenue anomalies',
            onTap: () {
              context.push('/anomalies');
            },
          ),

          const Divider(),

          // Settings Section
          _SectionHeader(title: l10n.settings),
          _MenuTile(
            icon: Icons.dark_mode,
            title: l10n.theme,
            subtitle: l10n.lightOrDarkMode,
            trailing: Switch(
              value: theme.brightness == Brightness.dark,
              onChanged: (value) async {
                await ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            onTap: null,
          ),
          _MenuTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: 'العربية / Français / English',
            onTap: () {
              _showLanguageDialog(context, ref);
            },
          ),

          const Divider(),

          // Help Section
          _SectionHeader(title: l10n.helpAndSupport),
          _MenuTile(
            icon: Icons.help_outline,
            title: l10n.helpCenter,
            subtitle: l10n.getHelp,
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          _MenuTile(
            icon: Icons.info_outline,
            title: l10n.about,
            subtitle: l10n.version,
            onTap: () {
              _showAboutDialog(context, l10n);
            },
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('العربية (Arabic)'),
                value: 'ar',
                groupValue: currentLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(languageProvider.notifier).setLanguage(value);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChangedToArabic)),
                      );
                    }
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Français (French)'),
                value: 'fr',
                groupValue: currentLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(languageProvider.notifier).setLanguage(value);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChangedToFrench)),
                      );
                    }
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: currentLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(languageProvider.notifier).setLanguage(value);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChangedToEnglish)),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.businessManagerApp,
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 ${l10n.businessManagerApp}\nBuilt with Flutter',
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.appDescription),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                AppSnackbar.success(context, l10n.logoutSuccess);
                // Don't manually navigate - let the router handle the redirect automatically
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: AppTypography.semiBold,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: AppTypography.semiBold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: trailing ?? (onTap != null 
          ? const Icon(Icons.chevron_right)
          : null),
      onTap: onTap,
    );
  }
}
