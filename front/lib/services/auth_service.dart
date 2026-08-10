import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  final ApiClient _client;

  AuthService(this._client);

  // ── Token storage ────────────────────────────────────────────────────────────

  /// Read the stored access token (used on cold start to warm up ApiClient).
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      print('Error reading stored access token: $e');
      return null;
    }
  }

  /// Read the stored refresh token (used on cold start to attempt refresh).
  Future<String?> getStoredRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error reading stored refresh token: $e');
      return null;
    }
  }

  /// Persist both tokens and immediately warm up ApiClient in-memory tokens.
  /// The in-memory set happens first so any request fired synchronously after
  /// this call already carries the Authorization header.
  Future<void> storeToken(String accessToken, [String? refreshToken]) async {
    _client.setToken(accessToken);
    if (refreshToken != null) {
      _client.setRefreshToken(refreshToken);
    }
    // Wire the silent-refresh callback so the interceptor can persist new
    // tokens to SharedPreferences after an automatic token rotation.
    _client.setOnTokenRefreshed((newAccess, newRefresh) async {
      if (newAccess == null) {
        // Refresh failed — clear storage to force re-login on next cold start.
        await clearToken();
        return;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, newAccess);
        if (newRefresh != null) {
          await prefs.setString(_refreshTokenKey, newRefresh);
        }
      } catch (e) {
        print('Warning: could not persist rotated tokens: $e');
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
    } catch (e) {
      print('Error storing tokens: $e');
      rethrow;
    }
  }

  /// Clear both tokens from memory and storage.
  Future<void> clearToken() async {
    _client.clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }

  // ── Auth endpoints ───────────────────────────────────────────────────────────

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data!);
      await storeToken(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Registration failed');
      }
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data!);
      await storeToken(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Login failed');
      }
      rethrow;
    }
  }

  /// Exchange a valid refresh token for a new access token (and rotated
  /// refresh token). Stores the new tokens automatically.
  /// Throws if the refresh token is expired or revoked.
  Future<void> refreshAccessToken() async {
    final storedRefreshToken = await getStoredRefreshToken();
    if (storedRefreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': storedRefreshToken},
      );

      final data = response.data!;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      await storeToken(newAccessToken, newRefreshToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired, please log in again');
      }
      rethrow;
    } catch (e) {
      // ApiClient._handleError wraps DioException into ApiException.
      final msg = e.toString().toLowerCase();
      if (msg.contains('unauthorized') || msg.contains('401') ||
          msg.contains('invalid') || msg.contains('revoked')) {
        await clearToken();
        throw Exception('Session expired, please log in again');
      }
      rethrow;
    }
  }

  /// Sends a password reset email. Always returns the server's safe message
  /// (same regardless of whether the email exists — prevents enumeration).
  /// Throws only on network/server errors, not on 200 "email not found" cases.
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return (response.data?['message'] as String?) ??
          'If an account exists with this email, a reset link has been sent';
    } on DioException catch (e) {
      final errorData = e.response?.data as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Failed to send reset email');
    }
  }

  /// Resets the user's password using the token from the email link.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      final errorData = e.response?.data as Map<String, dynamic>?;
      throw Exception(
          errorData?['message'] ?? 'Password reset failed. The link may have expired.');
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Authentication expired');
      }
      rethrow;
    } catch (e) {
      // ApiClient._handleError converts DioException to ApiException before
      // rethrowing — catch it here too so the auth provider can detect 401.
      final msg = e.toString().toLowerCase();
      if (msg.contains('unauthorized') || msg.contains('401')) {
        await clearToken();
        throw Exception('Authentication expired');
      }
      rethrow;
    }
  }

  /// Revokes the refresh token on the server, then clears local storage.
  Future<void> logout() async {
    final storedRefreshToken = await getStoredRefreshToken();

    // Clear local state immediately — don't let a network error block logout
    await clearToken();

    if (storedRefreshToken != null) {
      try {
        // Fire-and-forget: tell the server to revoke this refresh token.
        // If this fails (offline, expired token) the local session is still
        // cleared — worst case the server token expires naturally in 30 days.
        await _client.post<Map<String, dynamic>>(
          '/auth/logout',
          data: {'refreshToken': storedRefreshToken},
        );
      } catch (e) {
        print('Warning: server-side logout failed (token will expire naturally): $e');
      }
    }
  }
}
