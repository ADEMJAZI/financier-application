import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/business_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/glassy_nav_bar.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/products_screen.dart';
import '../expenses/expenses_screen.dart';
import '../debts/debts_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductsScreen(),
    const ExpensesScreen(),
    const DebtsScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch businessAutoRestoreProvider to ensure active business is restored
    ref.watch(businessAutoRestoreProvider);
    // Watch languageProvider so the whole tree rebuilds when language changes,
    // ensuring _DesktopLayout re-reads l10n from the updated context.
    ref.watch(languageProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppSpacing.breakpointMedium;

        if (useRail) {
          return _DesktopLayout(
            currentIndex: _currentIndex,
            onIndexChanged: (i) => setState(() => _currentIndex = i),
            screens: _screens,
          );
        }

        return _MobileLayout(
          currentIndex: _currentIndex,
          onIndexChanged: (i) => setState(() => _currentIndex = i),
          screens: _screens,
        );
      },
    );
  }
}

/// Mobile layout: content + bottom navigation bar
class _MobileLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> screens;

  const _MobileLayout({
    required this.currentIndex,
    required this.onIndexChanged,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    // Read l10n directly from context so it rebuilds when language changes
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: GlassyNavBar(
        currentIndex: currentIndex,
        onIndexChanged: onIndexChanged,
        items: _navItems(l10n),
      ),
    );
  }
}

/// Desktop layout: sidebar navigation rail + content area
class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> screens;

  const _DesktopLayout({
    required this.currentIndex,
    required this.onIndexChanged,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    // Read l10n directly from context so it rebuilds when language changes
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.sidebarDark : AppColors.sidebarLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar Rail ──────────────────────────────────
          Container(
            width: AppSpacing.sidebarWidth,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: BorderDirectional(
                end: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Logo area ──
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
                    ),
                    child: const Center(
                      child: Text(
                        'ت',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Nav items ──
                  ..._navItems(l10n).asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isSelected = i == currentIndex;
                    final color = isSelected ? primary : textSecondary;

                    return Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Tooltip(
                        message: item.label ?? '',
                        preferBelow: false,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onIndexChanged(i),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isSelected)
                                    PositionedDirectional(
                                      end: 0,
                                      top: 8,
                                      bottom: 8,
                                      child: Container(
                                        width: 3,
                                        decoration: BoxDecoration(
                                          color: primary,
                                          borderRadius: const BorderRadiusDirectional.all(Radius.circular(2)),
                                        ),
                                      ),
                                    ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? (item.activeIcon as Icon).icon
                                            : (item.icon as Icon).icon,
                                        color: color,
                                        size: 22,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.label ?? '',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: color,
                                          fontWeight: isSelected
                                              ? AppTypography.semiBold
                                              : AppTypography.regular,
                                          fontSize: 9,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Main Content ──────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared nav items used by both bottom bar and sidebar rail
List<BottomNavigationBarItem> _navItems(AppLocalizations l10n) {
  return [
    BottomNavigationBarItem(
      icon: const Icon(Icons.dashboard_outlined),
      activeIcon: const Icon(Icons.dashboard),
      label: l10n.dashboard,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.inventory_2_outlined),
      activeIcon: const Icon(Icons.inventory_2),
      label: l10n.stock,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.receipt_long_outlined),
      activeIcon: const Icon(Icons.receipt_long),
      label: l10n.expenses,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.payment_outlined),
      activeIcon: const Icon(Icons.payment),
      label: l10n.debts,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.more_horiz),
      activeIcon: const Icon(Icons.menu),
      label: l10n.more,
    ),
  ];
}
