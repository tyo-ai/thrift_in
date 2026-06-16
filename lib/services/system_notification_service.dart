import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'android_notification_service.dart';
import 'supabase_config.dart';
import 'user_service.dart';

class SystemNotificationService {
  SystemNotificationService._();

  static final SystemNotificationService instance =
      SystemNotificationService._();

  RealtimeChannel? _channel;
  int? _activeUserId;

  Future<void> startForCurrentUser() async {
    final userId = UserService.currentUserId;
    if (userId == null) {
      debugPrint('System notifications: skipped, no current user.');
      return;
    }
    if (_activeUserId == userId && _channel != null) {
      debugPrint('System notifications: already started for user $userId.');
      return;
    }

    await stop();
    _activeUserId = userId;
    await AndroidNotificationService.instance.initialize();
    debugPrint('System notifications: starting for user $userId.');

    _channel = SupabaseConfig.client
        .channel('system-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: _handleIncomingNotification,
        )
        .subscribe((status, error) {
          debugPrint(
            'System notifications realtime: $status${error == null ? '' : ' - $error'}',
          );
        });
  }

  Future<void> stop() async {
    final channel = _channel;
    _channel = null;
    _activeUserId = null;
    if (channel != null) {
      await SupabaseConfig.client.removeChannel(channel);
    }
  }

  void _handleIncomingNotification(PostgresChangePayload payload) async {
    final record = payload.newRecord;
    final title = record['title']?.toString() ?? 'Notifikasi Baru';
    final description = record['description']?.toString() ?? '';
    final id =
        int.tryParse(record['id']?.toString() ?? '') ??
        DateTime.now().millisecondsSinceEpoch % 100000;
    debugPrint('System notifications: incoming notification $id.');

    await AndroidNotificationService.instance.showNotification(
      id: id,
      title: title,
      body: description,
    );
  }
}
