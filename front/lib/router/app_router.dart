import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
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
                         state.matchedLocation == '/forgot-password' ||
                         state.matchedLocation.startsWith('/reset-password');

      // Still loading auth state — stay put, show nothing until resolved
      if (isAuthenticated == null) {
        // If heading somewhere protected, block until auth resolves
        if (!isAuthRoute) return null;
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          // Token arrives as a query parameter: /reset-password?token=xxx
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      
      // Business picker (post-auth landing)
      GoRoute(
        path: '/business-picker',
        builder: (context, state) => const BusinessPickerScreen(),
      ),
      
      // Main app routes (protected)
      GoRoute(
        path: '/',
        redirect: (context, state) => '/business-picker',
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/reserves',
        builder: (context, state) => const ReservesScreen(),
      ),
      GoRoute(
        path: '/cash-register',
        builder: (context, state) => const CashRegisterScreen(),
      ),
      GoRoute(
        path: '/waste',
        builder: (context, state) => const WasteScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/employees',
        builder: (context, state) => const EmployeesScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/reorder',
        builder: (context, state) => const ReorderScreen(),
      ),
      GoRoute(
        path: '/audit-log',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/menu-items',
        builder: (context, state) => const MenuItemsScreen(),
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesScreen(),
      ),
      GoRoute(
        path: '/order-history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/anomalies',
        builder: (context, state) => const AnomalyListScreen(),
      ),
    ],
  );
  
  ref.onDispose(() {
    authStream.close();
    router.dispose();
  });
  return router;
});
