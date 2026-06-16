import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidNotificationService {
  AndroidNotificationService._();

  static final AndroidNotificationService instance =
      AndroidNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<int, List<Message>> _chatNotificationMessages = {};

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

    final persistedMessages = await _loadChatNotificationMessages(
      roomId: roomId,
      senderName: trimmedSenderName,
    );
    final messages = _chatNotificationMessages.putIfAbsent(
      roomId,
      () => persistedMessages,
    );
    messages.add(
      Message(
        notificationMessage,
        DateTime.now(),
        Person(name: trimmedSenderName),
      ),
    );
    if (messages.length > 6) {
      messages.removeRange(0, messages.length - 6);
    }
    await _saveChatNotificationMessages(
      roomId: roomId,
      senderName: trimmedSenderName,
      messages: messages,
    );

    final androidDetails = AndroidNotificationDetails(
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
      styleInformation: MessagingStyleInformation(
        Person(name: 'Kamu'),
        conversationTitle: trimmedSenderName,
        groupConversation: false,
        messages: List<Message>.from(messages),
      ),
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
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

  Future<List<Message>> _loadChatNotificationMessages({
    required int roomId,
    required String senderName,
  }) async {
    if (_chatNotificationMessages.containsKey(roomId)) {
      return _chatNotificationMessages[roomId]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(_chatHistoryKey(roomId)) ?? const [];
    return rows.map((row) {
      try {
        final data = jsonDecode(row) as Map<String, dynamic>;
        return Message(
          data['text']?.toString() ?? '',
          DateTime.tryParse(data['time']?.toString() ?? '') ?? DateTime.now(),
          Person(name: data['sender']?.toString() ?? senderName),
        );
      } catch (_) {
        return Message(row, DateTime.now(), Person(name: senderName));
      }
    }).toList();
  }

  Future<void> _saveChatNotificationMessages({
    required int roomId,
    required String senderName,
    required List<Message> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _chatHistoryKey(roomId),
      messages.map((message) {
        return jsonEncode({
          'text': message.text,
          'time': message.timestamp.toIso8601String(),
          'sender': message.person?.name ?? senderName,
        });
      }).toList(),
    );
  }

  String _chatHistoryKey(int roomId) => 'chat_notification_history_$roomId';

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
