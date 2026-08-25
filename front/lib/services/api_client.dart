import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://financier-application.onrender.com/api';

  late final Dio _dio;

  // In-memory token — set immediately after a successful login/register so
  // that the very first downstream request (e.g. GET /businesses) always
  // carries the Authorization header without racing against a storage read.
  String? _token;
  String? _refreshToken;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Attach the in-memory token synchronously — no async storage read
          // on the hot path, so there is no window where the header is missing.
          // Only skip the token for unauthenticated auth endpoints (login,
          // register, refresh, logout, forgot-password, reset-password).
          // /auth/me requires the token — it IS an authenticated endpoint.
          const unauthenticatedPaths = [
            '/auth/login',
            '/auth/register',
            '/auth/refresh',
            '/auth/logout',
            '/auth/forgot-password',
            '/auth/reset-password',
            '/auth/verify-email',
            '/auth/resend-verification',
          ];
          final isUnauthenticated = unauthenticatedPaths.any(
            (p) => options.path == p || options.path.startsWith('$p?'),
          );
          if (_token != null && !isUnauthenticated) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          print('🌐 ${options.method} ${options.uri}');
          if (options.data != null) {
            print('📤 Request Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response [${response.statusCode}]: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error: ${error.message}');
          if (error.response != null) {
            print('Error Data: ${error.response?.data}');
          }

          final path = error.requestOptions.path;
          // Auth endpoints returning 401 = wrong credentials / expired refresh
          // token — do NOT attempt auto-refresh, just propagate the error.
          final isAuthEndpoint = path == '/auth/login' ||
              path == '/auth/register' ||
              path == '/auth/refresh' ||
              path == '/auth/logout' ||
              path == '/auth/forgot-password' ||
              path == '/auth/reset-password';

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            // Access token expired — try a silent refresh once.
            // Guard: don't retry if we already tried (prevents infinite loop).
            final isRetry = error.requestOptions.extra['_isRetry'] == true;
            if (!isRetry && _refreshToken != null) {
              try {
                // Exchange refresh token for a new access token
                final refreshResponse = await _dio.post(
                  '/auth/refresh',
                  data: {'refreshToken': _refreshToken},
                  options: Options(extra: {'_isRetry': true}),
                );
                final newAccess  = refreshResponse.data['accessToken']  as String;
                final newRefresh = refreshResponse.data['refreshToken'] as String;
                setToken(newAccess);
                setRefreshToken(newRefresh);

                // Persist to storage so the next cold start also has the new tokens.
                // We do this via a callback set by AuthService to avoid a circular dep.
                _onTokenRefreshed?.call(newAccess, newRefresh);

                // Retry the original request with the new token.
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                opts.extra['_isRetry'] = true;
                final retryResponse = await _dio.fetch(opts);
                return handler.resolve(retryResponse);
              } catch (_) {
                // Refresh failed — clear tokens, let caller handle 401.
                _token = null;
                _refreshToken = null;
                _onTokenRefreshed?.call(null, null);
              }
            } else {
              _token = null;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Callback invoked by the interceptor after a successful silent refresh,
  /// so AuthService can persist the new tokens to SharedPreferences without
  /// a circular dependency between ApiClient and AuthService.
  void Function(String? accessToken, String? refreshToken)? _onTokenRefreshed;

  void setOnTokenRefreshed(
      void Function(String? accessToken, String? refreshToken) callback) {
    _onTokenRefreshed = callback;
  }

  /// Set the bearer token that will be attached to every non-auth request.
  /// Call this immediately after receiving a token from login/register —
  /// before triggering any state change that causes downstream fetches.
  void setToken(String token) {
    _token = token;
  }

  /// Store the refresh token in memory so the interceptor can silently
  /// exchange it when the access token expires mid-session.
  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  /// Clear both in-memory tokens (call on logout or when a 401 is handled
  /// at a higher level).
  void clearToken() {
    _token = null;
    _refreshToken = null;
  }

  Dio get dio => _dio;
  
  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Error handler
  Exception _handleError(DioException error) {
    String message;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        if (data is Map && data.containsKey('message')) {
          message = data['message'] as String;
        } else {
          message = _getStatusCodeMessage(statusCode ?? 500);
        }
        break;
        
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
        
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          message = 'Cannot connect to server. Please check if the backend is running.';
        } else {
          message = 'An unexpected error occurred: ${error.message}';
        }
        break;
        
      default:
        message = 'An error occurred: ${error.message}';
    }
    
    return ApiException(message, error.response?.statusCode);
  }
  
  String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Resource already exists.';
      case 422:
        return 'Validation error.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Error occurred (Status: $statusCode)';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => message;
}
