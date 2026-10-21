import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/api_config.dart';

/// FCM: permission, foreground display via local notifications, and keeping
/// the backend's token in sync (`POST /api/auth/fcm-token/`, API ref A6).
///
/// The backend stores classic FCM tokens, so this keeps `getToken()` /
/// `onTokenRefresh` (deprecated in firebase_messaging 17 in favour of the
/// FID-based `register()`) until the backend supports FIDs.
// ignore_for_file: deprecated_member_use
class NotificationService {
  NotificationService(this._dio);

  final Dio _dio;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important updates',
    description: 'Property updates, bookings and offers',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Call once the user is logged in — asks for permission and registers
  /// the token. Safe to call again (e.g. on every app start while logged in).
  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      await _setupLocalNotifications();
      FirebaseMessaging.onMessage.listen(_showForeground);
      _messaging.onTokenRefresh.listen(_sendTokenToServer);
    }
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await syncToken();
  }

  Future<void> syncToken() async {
    final token = await _getToken();
    if (token != null) await _sendTokenToServer(token);
  }

  /// Logout: the next user on this device gets a fresh token.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }

  Future<void> _setupLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(settings: settings);
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<String?> _getToken() async {
    try {
      if (Platform.isIOS) {
        // FCM needs the APNs token first; it arrives asynchronously.
        // Simulators never get one — test push on a real device.
        for (var i = 0; i < 10; i++) {
          if (await _messaging.getAPNSToken() != null) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] token fetch failed: $e');
      return null;
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _dio.post(ApiConfig.fcmToken, data: {'fcm_token': token});
    } catch (e) {
      debugPrint('[FCM] token sync failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
