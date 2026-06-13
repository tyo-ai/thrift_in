import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidNotificationService {
  AndroidNotificationService._();

  static final AndroidNotificationService instance =
      AndroidNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final permissionGranted = await androidPlugin
        ?.requestNotificationsPermission();
    _notificationsEnabled =
        await androidPlugin?.areNotificationsEnabled() ??
        permissionGranted ??
        true;

    if (!_notificationsEnabled) {
      debugPrint('Thriftin notifications: Android permission is disabled.');
    }

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'thriftin_chat',
        'Chat Thriftin',
        description: 'Notifikasi untuk pesan chat baru',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'thriftin_general',
        'Notifikasi Thriftin',
        description: 'Notifikasi umum transaksi dan pesanan',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    _isInitialized = true;
  }

  Future<bool> _canShowNotifications() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    _notificationsEnabled =
        await androidPlugin?.areNotificationsEnabled() ?? _notificationsEnabled;
    if (!_notificationsEnabled) {
      debugPrint('Thriftin notifications: Android permission is disabled.');
    }
    return _notificationsEnabled;
  }

  Future<void> showChatNotification({
    required int roomId,
    required String senderName,
    required String message,
  }) async {
    await initialize();
    if (!await _canShowNotifications()) return;
    final trimmedSenderName = senderName.trim().isEmpty
        ? 'User Thriftin'
        : senderName.trim();
    final notificationMessage = message.trim().isEmpty
        ? 'Kamu menerima pesan baru'
        : message.trim();

    const androidDetails = AndroidNotificationDetails(
      'thriftin_chat',
      'Chat Thriftin',
      channelDescription: 'Notifikasi untuk pesan chat baru',
      icon: 'ic_notification',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: 'Pesan baru Thriftin',
      playSound: true,
      enableVibration: true,
      color: Color(0xFF159A5B),
      subText: 'ThriftIn',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id: roomId,
      title: trimmedSenderName,
      body: notificationMessage,
      notificationDetails: details,
      payload: 'chat:$roomId',
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    if (!await _canShowNotifications()) return;

    const androidDetails = AndroidNotificationDetails(
      'thriftin_general',
      'Notifikasi Thriftin',
      channelDescription: 'Notifikasi umum transaksi dan pesanan',
      icon: 'ic_notification',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      ticker: 'Notifikasi Thriftin',
      playSound: true,
      enableVibration: true,
      color: Color(0xFF1B8755),
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
