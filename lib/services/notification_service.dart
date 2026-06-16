import 'dart:async';

import 'supabase_config.dart';
import 'user_service.dart';

class NotificationService {
  static const Duration _cacheTtl = Duration(minutes: 2);
  static final Map<int, _NotificationCacheEntry> _cache = {};

  Future<void> createNotification({
    required int userId,
    required String title,
    required String description,
    String iconName = 'notifications',
    String iconColorHex = 'FF0D5C37',
    String iconBgColorHex = 'FFE8F5EE',
  }) async {
    await SupabaseConfig.client.from('notifications').insert({
      'user_id': userId,
      'iconName': iconName,
      'iconColorHex': iconColorHex,
      'iconBgColorHex': iconBgColorHex,
      'title': title,
      'time': DateTime.now().toIso8601String(),
      'description': description,
      'isUnread': 1,
    });
    unawaited(
      _sendPushNotification(
        userId: userId,
        title: title,
        body: description,
        payload: {'type': 'notification'},
      ),
    );
    _cache.remove(userId);
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    bool forceRefresh = false,
  }) async {
    final userId = UserService.currentUserId;
    if (userId == null) return [];

    final cached = _cache[userId];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return _cloneList(cached.items);
    }

    final results = await SupabaseConfig.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: false);

    final items = results
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    _cache[userId] = _NotificationCacheEntry(_cloneList(items));
    return _cloneList(items);
  }

  Future<void> markAllAsRead() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    await SupabaseConfig.client
        .from('notifications')
        .update({'isUnread': 0})
        .eq('user_id', userId);
    _cache.remove(userId);
  }

  static void clearCache() => _cache.clear();

  Future<void> _sendPushNotification({
    required int userId,
    required String title,
    required String body,
    required Map<String, String> payload,
  }) async {
    try {
      await SupabaseConfig.client.functions.invoke(
        'send-fcm',
        body: {
          'userId': userId,
          'title': title,
          'body': body,
          'payload': payload,
        },
      );
    } catch (_) {
      // Push is best-effort; the notification row remains the source of truth.
    }
  }

  List<Map<String, dynamic>> _cloneList(List<Map<String, dynamic>> items) {
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}

class _NotificationCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;

  _NotificationCacheEntry(this.items) : createdAt = DateTime.now();
}
