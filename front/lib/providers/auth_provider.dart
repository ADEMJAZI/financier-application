import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'business_provider.dart';
import 'service_providers.dart';

enum AuthStatus { unauthenticated, loading, authenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final authService = ref.read(authServiceProvider);

    try {
      final accessToken = await authService.getStoredToken();
      if (accessToken == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }

      // Warm up both tokens in ApiClient before any request fires.
      // storeToken with both tokens sets _token + _refreshToken + wires the
      // silent-refresh callback so mid-session expiry is handled automatically.
      final storedRefresh = await authService.getStoredRefreshToken();
      await authService.storeToken(accessToken, storedRefresh);

      // Try to validate the stored access token.
      try {
        final user = await authService.getMe();
        final storedToken = await authService.getStoredToken();
        if (storedToken != null) {
          NotificationService().init(ApiClient.baseUrl, storedToken);
        }
        return AuthState(status: AuthStatus.authenticated, user: user);
      } on Exception catch (e) {
        final msg = e.toString().toLowerCase();
        // Access token expired — attempt a silent refresh before giving up.
        // Match all possible forms: ApiException message, DioException, etc.
        final isExpired = msg.contains('authentication expired') ||
            msg.contains('unauthorized') ||
            msg.contains('401') ||
            msg.contains('token invalid') ||
            msg.contains('not authorized');
        if (isExpired) {
          try {
            await authService.refreshAccessToken();
            // refreshAccessToken() already called storeToken() internally,
            // so ApiClient._token is updated before this getMe() fires.
            final user = await authService.getMe();
            final storedToken = await authService.getStoredToken();
            if (storedToken != null) {
              NotificationService().init(ApiClient.baseUrl, storedToken);
            }
            return AuthState(status: AuthStatus.authenticated, user: user);
          } catch (_) {
            // Refresh token also gone/revoked — force re-login.
            await authService.clearToken();
            return const AuthState(status: AuthStatus.unauthenticated);
          }
        }
        await authService.clearToken();
        return const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      await authService.clearToken();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Clear all stored auth data - useful for debugging
  Future<void> clearStoredAuth() async {
    final authService = ref.read(authServiceProvider);
    await authService.clearToken();
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final authService = ref.read(authServiceProvider);
      final authResponse = await authService.login(email: email, password: password);

      // Wipe stale per-business data from any previous session.
      // Do NOT invalidate businessListProvider here — the token is now stored
      // and the Business Picker will fetch fresh data when it mounts.
      ref.read(activeBusinessProvider.notifier).clearActiveBusiness();

      // Initialize NotificationService with FCM
      NotificationService().init(ApiClient.baseUrl, authResponse.accessToken);

      state = AsyncValue.data(
        AuthState(status: AuthStatus.authenticated, user: authResponse.user),
      );
    } catch (e) {
      // Store the error in state so the login screen can read it.
      // Do NOT rethrow — rethrowing propagates to the router refresh stream,
      // which tries to redirect to /login while already there, disrupting
      // the navigation stack and causing the "lost connection" crash.
      state = AsyncValue.data(
        AuthState(status: AuthStatus.unauthenticated, error: e.toString()),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authService = ref.read(authServiceProvider);
      final authResponse = await authService.register(
        name: name,
        email: email,
        password: password,
      );

      // Same as login — wipe stale state, let the picker re-fetch naturally.
      ref.read(activeBusinessProvider.notifier).clearActiveBusiness();

      NotificationService().init(ApiClient.baseUrl, authResponse.accessToken);

      state = AsyncValue.data(
        AuthState(status: AuthStatus.authenticated, user: authResponse.user),
      );
    } catch (e) {
      state = AsyncValue.data(
        AuthState(status: AuthStatus.unauthenticated, error: e.toString()),
      );
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);

    // authService.logout() clears local tokens immediately AND revokes the
    // refresh token on the server (fire-and-forget if offline).
    await authService.logout();

    // Clear active business state and all per-business cached data.
    ref.read(activeBusinessProvider.notifier).clearActiveBusiness();
    
    // Changing the state to unauthenticated automatically triggers all providers
    // that watch authProvider (like businessListProvider) to rebuild.
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Convenience provider for checking auth status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.when(
    data: (authState) => authState.status == AuthStatus.authenticated,
    loading: () => false,
    error: (e, s) => false,
  );
});

// Convenience provider for getting current user
final currentUserProvider = Provider<User?>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.when(
    data: (authState) => authState.user,
    loading: () => null,
    error: (e, s) => null,
  );
});