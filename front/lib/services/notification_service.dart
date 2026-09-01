import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _backendApiUrl;
  String? _authToken;

  /// Initialize the notification service with API URL and Auth token
  /// Call this after successful login.
  void init(String apiUrl, String token) {
    _backendApiUrl = apiUrl;
    _authToken = token;

    _setupFirebase();
  }

  Future<void> _setupFirebase() async {
    // Guard: if Firebase wasn't initialised (placeholder google-services.json),
    // skip silently — the rest of the app works without push notifications.
    try {
      // Request permissions for iOS and Android 13+
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
        return;
      }

      // Get FCM token
      try {
        String? fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          await _registerTokenWithBackend(fcmToken);
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
        _registerTokenWithBackend(fcmToken);
      }).onError((err) {
        debugPrint('Error refreshing FCM token: $err');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification?.title}');
        }
      });
    } catch (e) {
      debugPrint('Firebase Messaging setup skipped (placeholder config): $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    if (_backendApiUrl == null || _authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_backendApiUrl/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token registered successfully with backend');
      } else {
        debugPrint('Failed to register FCM token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error registering FCM token with backend: $e');
    }
  }

  /// Call this before logging out
  Future<void> unregisterToken(String apiUrl, String token) async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null) return;

      final response = await http.post(
        Uri.parse('$apiUrl/notifications/unregister-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token unregistered successfully');
      }

      // Also delete the token from the device
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      // Silently swallow — logout must not be blocked by notification errors
      debugPrint('FCM unregister skipped: $e');
    }
  }
}
