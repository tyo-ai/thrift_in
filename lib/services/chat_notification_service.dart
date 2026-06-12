import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'android_notification_service.dart';
import 'chat_service.dart';
import 'supabase_config.dart';
import 'user_service.dart';
import '../screens/chat_screen.dart';

class ChatNotificationService {
  ChatNotificationService._();

  static final ChatNotificationService instance = ChatNotificationService._();

  RealtimeChannel? _channel;
  int? _activeUserId;
  Set<int> _roomIds = {};
  final ChatService _chatService = ChatService();
  VoidCallback? _onNewMessage;
  
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> startForCurrentUser({VoidCallback? onNewMessage}) async {
    _onNewMessage = onNewMessage;
    final userId = UserService.currentUserId;
    if (userId == null) {
      debugPrint('Chat notifications: skipped, no current user.');
      return;
    }
    if (_activeUserId == userId && _channel != null) {
      // Update callback even if already started
      _onNewMessage = onNewMessage;
      debugPrint('Chat notifications: already started for user $userId.');
      return;
    }

    await stop();
    _activeUserId = userId;
    await AndroidNotificationService.instance.initialize();
    await _refreshRoomIds(userId);
    debugPrint(
      'Chat notifications: starting for user $userId with ${_roomIds.length} rooms.',
    );

    _channel = SupabaseConfig.client
        .channel('chat-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) => _handleIncomingMessage(userId, payload),
        )
        .subscribe((status, error) {
          debugPrint(
            'Chat notifications realtime: $status${error == null ? '' : ' - $error'}',
          );
        });
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
    if (senderId == null || roomId == null) {
      debugPrint('Chat notifications: ignored invalid payload $record');
      return;
    }
    if (senderId == userId) {
      debugPrint('Chat notifications: ignored own message in room $roomId.');
      return;
    }

    if (!_roomIds.contains(roomId)) {
      await _refreshRoomIds(userId);
      if (!_roomIds.contains(roomId)) {
        debugPrint(
          'Chat notifications: ignored room $roomId, not owned by user $userId.',
        );
        return;
      }
    }

    final room = await _findRoom(userId, roomId);
    final senderName = _senderNameFromRoom(room, senderId);
    debugPrint(
      'Chat notifications: incoming message from $senderName in room $roomId.',
    );

    // Trigger live badge update on main nav
    _onNewMessage?.call();

    // Trigger stream for active chat screens to refresh in real-time
    _messageController.add(record);

    if (ChatScreen.activeRoomId == roomId) {
      debugPrint('Chat notifications: skipped active room $roomId.');
      return;
    }

    await AndroidNotificationService.instance.showChatNotification(
      roomId: roomId,
      senderName: senderName,
      message: ChatService.previewText(record['message']?.toString() ?? ''),
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
