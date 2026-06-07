import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AndroidNotificationService {
  AndroidNotificationService._();

  static final AndroidNotificationService instance =
      AndroidNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> showChatNotification({
    required int roomId,
    required String senderName,
    required String message,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'thriftin_chat',
      'Chat Thriftin',
      channelDescription: 'Notifikasi untuk pesan chat baru',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id: roomId,
      title: 'Pesan baru dari $senderName',
      body: message.isEmpty ? 'Kamu menerima pesan baru' : message,
      notificationDetails: details,
      payload: 'chat:$roomId',
    );
  }
}
