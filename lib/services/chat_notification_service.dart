import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/chat_screen.dart';
import 'android_notification_service.dart';
import 'chat_service.dart';
import 'in_app_notification_service.dart';
import 'supabase_config.dart';
import 'user_service.dart';

class ChatNotificationService {
  ChatNotificationService._();

  static final ChatNotificationService instance = ChatNotificationService._();

  RealtimeChannel? _channel;
  int? _activeUserId;
  Set<int> _roomIds = {};
  final ChatService _chatService = ChatService();
  VoidCallback? _onNewMessage;

  Future<void> startForCurrentUser({VoidCallback? onNewMessage}) async {
    _onNewMessage = onNewMessage;
    final userId = UserService.currentUserId;
    if (userId == null) return;
    if (_activeUserId == userId && _channel != null) {
      // Update callback even if already started
      _onNewMessage = onNewMessage;
      return;
    }

    await stop();
    _activeUserId = userId;
    await AndroidNotificationService.instance.initialize();
    await _refreshRoomIds(userId);

    _channel = SupabaseConfig.client
        .channel('chat-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) => _handleIncomingMessage(userId, payload),
        )
        .subscribe();
  }

  Future<void> stop() async {
    final channel = _channel;
    _channel = null;
    _activeUserId = null;
    _roomIds = {};
    if (channel != null) {
      await SupabaseConfig.client.removeChannel(channel);
    }
  }

  Future<void> _handleIncomingMessage(
    int userId,
    PostgresChangePayload payload,
  ) async {
    final record = payload.newRecord;
    final senderId = int.tryParse(record['sender_id']?.toString() ?? '');
    final roomId = int.tryParse(record['room_id']?.toString() ?? '');
    if (senderId == null || roomId == null || senderId == userId) return;

    if (!_roomIds.contains(roomId)) {
      await _refreshRoomIds(userId);
      if (!_roomIds.contains(roomId)) return;
    }

    final room = await _findRoom(userId, roomId);
    final senderName = _senderNameFromRoom(room, senderId);

    // Trigger live badge update on main nav
    _onNewMessage?.call();

    // Show in-app banner popup if user is not currently in the active chat room
    if (ChatScreen.activeRoomId != roomId && room != null) {
      InAppNotificationService.show(
        room: room,
        senderName: senderName,
        message: record['message']?.toString() ?? '',
      );
    }

    await AndroidNotificationService.instance.showChatNotification(
      roomId: roomId,
      senderName: senderName,
      message: record['message']?.toString() ?? '',
    );
  }

  Future<void> _refreshRoomIds(int userId) async {
    final rooms = await _chatService.getRoomsForUser(
      userId,
      forceRefresh: true,
    );
    _roomIds = rooms
        .map((room) => int.tryParse(room['id']?.toString() ?? ''))
        .whereType<int>()
        .toSet();
  }

  Future<Map<String, dynamic>?> _findRoom(int userId, int roomId) async {
    final rooms = await _chatService.getRoomsForUser(
      userId,
      forceRefresh: true,
    );
    for (final room in rooms) {
      if (room['id']?.toString() == roomId.toString()) return room;
    }
    return null;
  }

  String _senderNameFromRoom(Map<String, dynamic>? room, int senderId) {
    if (room == null) return 'User Thriftin';
    final buyer = room['buyer'];
    final seller = room['seller'];
    final isBuyerSender = room['buyer_id']?.toString() == senderId.toString();
    final sender = isBuyerSender ? buyer : seller;
    if (sender is Map) {
      final name = sender['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'User Thriftin';
  }
}
