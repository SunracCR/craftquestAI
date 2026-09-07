import 'dart:async';
import 'dart:io';

import 'package:craftquest_app/core/auth/token_storage.dart';
import 'package:craftquest_app/core/billing/membership_billing_refresh_coordinator.dart';
import 'package:craftquest_app/core/di/injection.dart';
import 'package:craftquest_app/core/navigation/app_keys.dart';
import 'package:craftquest_app/features/notifications/data/notification_repository.dart';
import 'package:craftquest_app/features/notifications/presentation/notification_navigation.dart';
import 'package:craftquest_app/features/notifications/data/models/notification_models.dart';
import 'package:craftquest_app/features/notifications/presentation/notifications_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Inicialización diferida de push (R3) y registro de token FCM/APNs.
class PushNotificationService {
  PushNotificationService(this._repository);

  final NotificationRepository _repository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  bool _firebaseReady = false;
  bool _listenersBound = false;
  Future<void>? _initFuture;
  Future<void>? _registerInFlight;

  Future<void> initializeDeferred() async {
    if (kIsWeb) {
      return;
    }

    _initFuture ??= _initializeInternal();
    await _initFuture;
  }

  Future<void> _initializeInternal() async {
    if (_firebaseReady) {
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      _initFuture = null;
      _logPush('Firebase.initializeApp failed', error, stackTrace);
      return;
    }

    try {
      await _setupLocalNotifications();
      await _requestPermissions();
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _bindListeners();
      await _handleInitialMessage();
      _firebaseReady = true;
      _logPush('Firebase push initialized');
    } catch (error, stackTrace) {
      _initFuture = null;
      _logPush('Push setup failed after Firebase init', error, stackTrace);
    }
  }

  Future<void> onAuthenticated() async {
    await initializeDeferred();
    if (!_firebaseReady) {
      _logPush('Skipping token registration: Firebase not ready');
      return;
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
    } catch (error, stackTrace) {
      _logPush('removeDeviceToken failed', error, stackTrace);
    }
    _currentToken = null;
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
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
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _logPush(
        'iOS notification authorization: ${settings.authorizationStatus}',
      );
    } else if (Platform.isAndroid) {
      final granted = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _logPush('Android POST_NOTIFICATIONS granted: $granted');
    }
  }

  Future<void> _registerTokenWithBackend() async {
    final inFlight = _registerInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _registerTokenWithBackendInternal();
    _registerInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_registerInFlight, future)) {
        _registerInFlight = null;
      }
    }
  }

  Future<void> _registerTokenWithBackendInternal() async {
    try {
      if (!await _hasAuthenticatedSession()) {
        _logPush('Token registration skipped: no authenticated session');
        return;
      }

      if (Platform.isIOS) {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          _logPush('Token registration skipped: notifications denied');
          return;
        }
      }

      final token = await _resolveFcmToken();
      if (token == null || token.isEmpty) {
        _logPush('FCM getToken returned empty');
        return;
      }
      if (token == _currentToken) {
        return;
      }

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web';
      await _repository.registerDeviceToken(token: token, platform: platform);
      _currentToken = token;
      _logPush('Device token registered ($platform)');
    } catch (error, stackTrace) {
      _logPush('registerDeviceToken failed', error, stackTrace);
    }
  }

  Future<String?> _resolveFcmToken() async {
    if (Platform.isIOS) {
      final apnsToken = await _waitForApnsToken();
      if (apnsToken == null) {
        _logPush('APNs token not available; FCM token cannot be requested yet');
        return null;
      }
    }

    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (error, stackTrace) {
        lastError = error;
        lastStack = stackTrace;
        _logPush('FCM getToken attempt ${attempt + 1} failed', error, stackTrace);
      }
      await Future<void>.delayed(Duration(seconds: 1 + attempt));
    }

    if (lastError != null) {
      _logPush('FCM getToken exhausted retries', lastError, lastStack);
    }
    return null;
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 15; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          _logPush('APNs token ready');
          return token;
        }
      } catch (error, stackTrace) {
        _logPush('getAPNSToken attempt ${attempt + 1} failed', error, stackTrace);
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
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

  void _bindListeners() {
    if (_listenersBound) {
      return;
    }
    _listenersBound = true;
    _listenForTokenRefresh();
    _listenForForegroundMessages();
    _listenForOpenedApp();
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
        _logPush('Device token refreshed ($platform)');
      } catch (error, stackTrace) {
        _logPush('onTokenRefresh registration failed', error, stackTrace);
      }
    });
  }

  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final type = message.data['type'] as String?;
      final coordinator = getIt<MembershipBillingRefreshCoordinator>();
      if (coordinator.shouldRefreshForNotification(type)) {
        unawaited(coordinator.refreshForNotification(type!));
      }

      final notification = message.notification;
      if (notification == null) {
        return;
      }
      // En iOS el sistema muestra el banner con setForegroundNotificationPresentationOptions.
      if (Platform.isIOS) {
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
    final type = data['type'] as String? ?? '';
    final coordinator = getIt<MembershipBillingRefreshCoordinator>();
    if (coordinator.shouldRefreshForNotification(type)) {
      await coordinator.refreshForNotification(type);
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
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

  void _logPush(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint(
      '[PushNotificationService] $message${error != null ? ': $error' : ''}',
    );
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
