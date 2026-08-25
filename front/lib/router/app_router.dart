import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_reset_code_screen.dart';
import '../screens/auth/set_new_password_screen.dart';
import '../screens/business_picker/business_picker_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/reserves/reserves_screen.dart';
import '../screens/cash_register/cash_register_screen.dart';
import '../screens/waste/waste_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/employees/employees_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reorder/reorder_screen.dart';
import '../screens/audit_log/audit_log_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/menu_items/menu_items_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/ai/anomaly_list_screen.dart';
import '../widgets/app_animations.dart';
import '../screens/auth/verify_email_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Helper class to make router reactive to auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}


final appRouterProvider = Provider<GoRouter>((ref) {
  // Convert provider changes to a stream
  final authStream = StreamController<AuthState>.broadcast();
  ref.listen(authProvider, (previous, next) {
    next.whenData((authState) => authStream.add(authState));
  });
  
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream.stream),
    redirect: (context, state) {
      final authAsync = ref.watch(authProvider);
      final isAuthenticated = authAsync.when(
        data: (authState) => authState.status == AuthStatus.authenticated,
        loading: () => null, // Still loading
        error: (e, s) => false,
      );

      final isAuthRoute = state.matchedLocation == '/login' ||
                         state.matchedLocation == '/register' ||
                         state.matchedLocation == '/verify-email' ||
                         state.matchedLocation == '/forgot-password' ||
                         state.matchedLocation == '/verify-reset-code' ||
                         state.matchedLocation == '/set-new-password';

      // Still loading auth state — show login screen instead of blank screen.
      // Once auth resolves, refreshListenable will re-trigger redirect.
      if (isAuthenticated == null) {
        if (!isAuthRoute) return '/login';
        return null;
      }

      // Redirect unauthenticated users to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Redirect authenticated users away from auth screens to business picker
      if (isAuthenticated && isAuthRoute) {
        return '/business-picker';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          // Email is passed as a query parameter: /verify-email?email=xxx@xxx.com
          final email = state.uri.queryParameters['email'] ?? '';
          return AnimatedPageTransition(child: VerifyEmailScreen(email: email));
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            AnimatedPageTransition(child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/verify-reset-code',
        pageBuilder: (context, state) {
          final email =
              Uri.decodeComponent(state.uri.queryParameters['email'] ?? '');
          return AnimatedPageTransition(
              child: VerifyResetCodeScreen(email: email));
        },
      ),
      GoRoute(
        path: '/set-new-password',
        pageBuilder: (context, state) {
          final token =
              Uri.decodeComponent(state.uri.queryParameters['token'] ?? '');
          return AnimatedPageTransition(
              child: SetNewPasswordScreen(resetSessionToken: token));
        },
      ),
      
      // Business picker (post-auth landing)
      GoRoute(
        path: '/business-picker',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const BusinessPickerScreen()),
      ),
      
      // Main app routes (protected)
      GoRoute(
        path: '/',
        redirect: (context, state) => '/business-picker',
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const HomeScreen()),
      ),
      GoRoute(
        path: '/reserves',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const ReservesScreen()),
      ),
      GoRoute(
        path: '/cash-register',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const CashRegisterScreen()),
      ),
      GoRoute(
        path: '/waste',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const WasteScreen()),
      ),
      GoRoute(
        path: '/suppliers',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const SuppliersScreen()),
      ),
      GoRoute(
        path: '/employees',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const EmployeesScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const ReportsScreen()),
      ),
      GoRoute(
        path: '/reorder',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const ReorderScreen()),
      ),
      GoRoute(
        path: '/audit-log',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const AuditLogScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/menu-items',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const MenuItemsScreen()),
      ),
      GoRoute(
        path: '/sales',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const SalesScreen()),
      ),
      GoRoute(
        path: '/order-history',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const OrderHistoryScreen()),
      ),
      GoRoute(
        path: '/anomalies',
        pageBuilder: (context, state) => AnimatedPageTransition(child: const AnomalyListScreen()),
      ),
    ],
  );
  
  ref.onDispose(() {
    authStream.close();
    router.dispose();
  });
  return router;
});


