import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'android_notification_service.dart';
import 'supabase_config.dart';

class FirebaseNotificationService {
  FirebaseNotificationService._();

  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;
  bool _firebaseAvailable = false;

  static Future<bool> ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp().timeout(const Duration(seconds: 4));
      }
      return true;
    } catch (error) {
      debugPrint(
        'FCM skipped: Firebase belum dikonfigurasi. '
        'Tambahkan android/app/google-services.json. Detail: $error',
      );
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _firebaseAvailable = await ensureFirebaseInitialized();
    if (!_firebaseAvailable) return;

    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;

    try {
      await AndroidNotificationService.instance.initialize().timeout(
        const Duration(seconds: 4),
      );
      await _requestPermission().timeout(const Duration(seconds: 4));
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint('FCM notification setup skipped: $error');
      return;
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> registerCurrentDevice(int userId) async {
    await initialize();
    final messaging = _messaging;
    if (!_firebaseAvailable || messaging == null) return;

    try {
      final token = await messaging.getToken().timeout(
        const Duration(seconds: 6),
      );
      if (token != null && token.isNotEmpty) {
        await _saveToken(userId: userId, token: token);
      }

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        if (newToken.isNotEmpty) {
          _saveToken(userId: userId, token: newToken);
        }
      });
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> removeCurrentDeviceToken({int? userId}) async {
    await initialize();
    final messaging = _messaging;
    if (!_firebaseAvailable || messaging == null) return;

    try {
      final token = await messaging.getToken().timeout(
        const Duration(seconds: 6),
      );
      if (token == null || token.isEmpty) return;

      var query = SupabaseConfig.client
          .from('user_fcm_tokens')
          .delete()
          .eq('token', token);
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      await query;
    } catch (error) {
      debugPrint('FCM token removal failed: $error');
    }
  }

  Future<void> _requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _saveToken({required int userId, required String token}) async {
    await SupabaseConfig.client.from('user_fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': _platformName,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
    debugPrint('FCM token registered for user $userId.');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM foreground skipped local notification: ${message.messageId}',
    );
  }

  static Future<void> showLocalNotificationFromMessage(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'ThriftIn';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'Kamu punya notifikasi baru';
    final payload =
        message.data['payload']?.toString() ??
        message.data['route']?.toString() ??
        message.data['type']?.toString();
    final type = message.data['type']?.toString();
    final roomId = int.tryParse(message.data['roomId']?.toString() ?? '');

    if (type == 'chat' && roomId != null) {
      await AndroidNotificationService.instance.showChatNotification(
        roomId: roomId,
        senderName: title,
        message: body,
      );
      return;
    }

    await AndroidNotificationService.instance.showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: payload,
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final ready = await FirebaseNotificationService.ensureFirebaseInitialized();
  if (!ready) return;

  // Android menampilkan notification payload sendiri saat background.
  // Data-only payload perlu local notification manual.
  if (message.notification == null) {
    await FirebaseNotificationService.showLocalNotificationFromMessage(message);
  }
}
