import 'dart:async';
import 'dart:io';

import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/features/notifications/data/notification_repository.dart';
import 'package:craftquest_app/features/notifications/presentation/notification_navigation.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Inicialización diferida de push (R3) y registro de token FCM/APNs.
class PushNotificationService {
  PushNotificationService(this._repository);

  final NotificationRepository _repository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  bool _initialized = false;

  Future<void> initializeDeferred() async {
    if (_initialized || kIsWeb) {
      return;
    }

    _initialized = true;
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Sin google-services / GoogleService-Info: push deshabilitado en dev.
      return;
    }

    await _setupLocalNotifications();
    await _requestPermissions();
    _listenForTokenRefresh();
    _listenForForegroundMessages();
    _listenForOpenedApp();
    await _handleInitialMessage();
  }

  Future<void> onAuthenticated() async {
    if (!_initialized) {
      await initializeDeferred();
    }
    await _registerTokenWithBackend();
  }

  Future<void> onLogout() async {
    final token = _currentToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await _repository.removeDeviceToken(token);
    } catch (_) {
      // Best effort.
    }
    _currentToken = null;
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        unawaited(_openFromPayload(payload));
      },
    );

    const channel = AndroidNotificationChannel(
      'craftquest_default',
      'CraftQuest',
      description: 'Notificaciones de CraftQuest',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    } else if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _registerTokenWithBackend() async {
    try {
      if (!await _hasAuthenticatedSession()) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty || token == _currentToken) {
        return;
      }
      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web';
      await _repository.registerDeviceToken(token: token, platform: platform);
      _currentToken = token;
    } catch (_) {
      // Best effort.
    }
  }

  Future<bool> _hasAuthenticatedSession() async {
    final storage = getIt<TokenStorage>();
    final access = await storage.getAccessToken();
    if (access != null && access.isNotEmpty) {
      return true;
    }
    final refresh = await storage.getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  void _listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        if (!await _hasAuthenticatedSession()) {
          return;
        }
        final platform = Platform.isIOS ? 'ios' : 'android';
        await _repository.registerDeviceToken(token: token, platform: platform);
        _currentToken = token;
      } catch (_) {}
    });
  }

  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) {
        return;
      }
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'craftquest_default',
            'CraftQuest',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: _encodePayload(message.data),
      );
    });
  }

  void _listenForOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_openFromData(message.data));
    });
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      await _openFromData(message.data);
    }
  }

  Future<void> _openFromPayload(String payload) async {
    final parts = payload.split('|');
    if (parts.length < 2) {
      return;
    }
    await _openFromData({
      'type': parts[0],
      if (parts.length > 1) 'route': parts[1],
    });
  }

  Future<void> _openFromData(Map<String, dynamic> data) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final notification = NotificationModel(
      notificationId: 'push',
      type: data['type'] as String? ?? '',
      title: '',
      body: '',
      isRead: true,
      createdAt: DateTime.now().toUtc(),
      data: NotificationPayloadModel(
        quizId: data['quizId'] as String?,
        classId: data['classId'] as String?,
        assignmentId: data['assignmentId'] as String?,
        aiJobId: data['aiJobId'] as String?,
        route: data['route'] as String?,
      ),
    );

    await NotificationNavigation.open(context, notification);
    getIt<NotificationsCubit>().refreshUnreadCount();
  }

  String _encodePayload(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final route = data['route'] as String? ?? '';
    return '$type|$route';
  }
}
