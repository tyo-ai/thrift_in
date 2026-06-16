import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class ChatService {
  static const String imageMessagePrefix = '__thriftin_image__:';
  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<int, _ChatRoomsCacheEntry> _roomsCache = {};

  static bool isImageMessage(String message) =>
      imageUrlFromMessage(message) != null;

  static String? imageUrlFromMessage(String message) {
    final trimmed = message.trim();
    if (!trimmed.startsWith(imageMessagePrefix)) return null;
    final url = trimmed.substring(imageMessagePrefix.length).trim();
    return url.isEmpty ? null : url;
  }

  static String previewText(String message) {
    return isImageMessage(message) ? 'Mengirim gambar' : message;
  }

  Future<Map<String, dynamic>> getOrCreateRoom({
    required int productId,
    required int buyerId,
    required int sellerId,
  }) async {
    final existing = await SupabaseConfig.client
        .from('chat_rooms')
        .select(
          '*, products(name, imageUrl, price, seller_id, storeName), '
          'buyer:users!chat_rooms_buyer_id_fkey(name, photo_path), '
          'seller:users!chat_rooms_seller_id_fkey(name, photo_path)',
        )
        .eq('product_id', productId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) {
      return _mapRoom(existing);
    }

    final now = DateTime.now().toIso8601String();
    final room = await SupabaseConfig.client
        .from('chat_rooms')
        .insert({
          'product_id': productId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'last_message': 'Mulai percakapan',
          'last_message_at': now,
          'created_at': now,
        })
        .select(
          '*, products(name, imageUrl, price, seller_id, storeName), '
          'buyer:users!chat_rooms_buyer_id_fkey(name, photo_path), '
          'seller:users!chat_rooms_seller_id_fkey(name, photo_path)',
        )
        .single();

    _invalidateUsers(buyerId, sellerId);
    return _mapRoom(room);
  }

  Future<List<Map<String, dynamic>>> getRoomsForUser(
    int userId, {
    bool forceRefresh = false,
  }) async {
    final cached = _roomsCache[userId];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return _cloneList(cached.rooms);
    }

    final results = await SupabaseConfig.client
        .from('chat_rooms')
        .select(
          '*, products(name, imageUrl, price, seller_id, storeName), '
          'buyer:users!chat_rooms_buyer_id_fkey(name, photo_path), '
          'seller:users!chat_rooms_seller_id_fkey(name, photo_path)',
        )
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false, nullsFirst: false)
        .order('id', ascending: false);

    final rooms = <Map<String, dynamic>>[];
    for (final row in results) {
      final room = _mapRoom(row);
      final roomId = int.tryParse(room['id']?.toString() ?? '');
      if (roomId != null) {
        room['unread'] = await getUnreadCount(roomId, userId);
      }
      rooms.add(room);
    }

    _roomsCache[userId] = _ChatRoomsCacheEntry(_cloneList(rooms));
    return _cloneList(rooms);
  }

  Future<List<Map<String, dynamic>>> getMessages(int roomId) async {
    final results = await SupabaseConfig.client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at')
        .order('id');

    return results.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> sendMessage({
    required int roomId,
    required int senderId,
    required String message,
    int? offerAmount,
  }) async {
    final now = DateTime.now().toIso8601String();
    final preview = offerAmount == null
        ? previewText(message)
        : 'Menawarkan Rp $offerAmount';
    await SupabaseConfig.client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'message': message,
      'offer_amount': offerAmount,
      'created_at': now,
    });

    await SupabaseConfig.client
        .from('chat_rooms')
        .update({'last_message': preview, 'last_message_at': now})
        .eq('id', roomId);
    unawaited(
      _sendChatPushNotification(
        roomId: roomId,
        senderId: senderId,
        message: preview,
      ),
    );
    _roomsCache.clear();
  }

  Future<String> uploadChatImage({
    required File imageFile,
    required int roomId,
    required int senderId,
  }) async {
    if (!await imageFile.exists()) {
      throw ArgumentError('File gambar chat tidak ditemukan.');
    }

    final extension = imageFile.path.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final objectPath =
        'chat/$roomId/$senderId-${DateTime.now().microsecondsSinceEpoch}.$safeExtension';

    await SupabaseConfig.client.storage
        .from('product-images')
        .upload(
          objectPath,
          imageFile,
          fileOptions: FileOptions(
            upsert: true,
            contentType: safeExtension == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    return SupabaseConfig.client.storage
        .from('product-images')
        .getPublicUrl(objectPath);
  }

  Future<String> uploadChatImageBytes({
    required Uint8List bytes,
    required String originalPath,
    required int roomId,
    required int senderId,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('File gambar chat kosong.');
    }

    final extension = originalPath.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty || extension.length > 5
        ? 'jpg'
        : extension;
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final objectPath =
        'chat/$roomId/$senderId-${DateTime.now().microsecondsSinceEpoch}.$safeExtension';

    await SupabaseConfig.client.storage
        .from('product-images')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );

    return SupabaseConfig.client.storage
        .from('product-images')
        .getPublicUrl(objectPath);
  }

  Future<int> getUnreadCount(int roomId, int userId) async {
    final results = await SupabaseConfig.client
        .from('chat_messages')
        .select('id')
        .eq('room_id', roomId)
        .neq('sender_id', userId)
        .eq('is_read', 0);

    return results.length;
  }

  Future<int> getTotalUnreadCount(int userId) async {
    final rooms = await getRoomsForUser(userId, forceRefresh: true);
    var total = 0;
    for (final room in rooms) {
      total += int.tryParse(room['unread']?.toString() ?? '') ?? 0;
    }
    return total;
  }

  Future<void> markRoomAsRead({
    required int roomId,
    required int userId,
  }) async {
    await SupabaseConfig.client
        .from('chat_messages')
        .update({'is_read': 1})
        .eq('room_id', roomId)
        .neq('sender_id', userId);
    _roomsCache.remove(userId);
  }

  Future<void> deleteRoom(int roomId) async {
    await SupabaseConfig.client.from('chat_rooms').delete().eq('id', roomId);
    _roomsCache.clear();
  }

  Future<void> _sendChatPushNotification({
    required int roomId,
    required int senderId,
    required String message,
  }) async {
    try {
      final room = await SupabaseConfig.client
          .from('chat_rooms')
          .select(
            'buyer_id, seller_id, buyer:users!chat_rooms_buyer_id_fkey(name), seller:users!chat_rooms_seller_id_fkey(name)',
          )
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return;

      final buyerId = int.tryParse(room['buyer_id']?.toString() ?? '');
      final sellerId = int.tryParse(room['seller_id']?.toString() ?? '');
      final recipientId = senderId == buyerId ? sellerId : buyerId;
      if (recipientId == null || recipientId == senderId) return;

      final sender = senderId == buyerId ? room['buyer'] : room['seller'];
      final senderName = sender is Map
          ? sender['name']?.toString().trim() ?? 'User ThriftIn'
          : 'User ThriftIn';

      await SupabaseConfig.client.functions.invoke(
        'send-fcm',
        body: {
          'userId': recipientId,
          'title': senderName.isEmpty ? 'Pesan baru' : senderName,
          'body': message,
          'payload': {'type': 'chat', 'roomId': roomId.toString()},
        },
      );
    } catch (_) {
      // Realtime chat remains usable even if push delivery fails.
    }
  }

  Future<void> deleteMessage({
    required int roomId,
    required int messageId,
  }) async {
    await SupabaseConfig.client
        .from('chat_messages')
        .delete()
        .eq('id', messageId);

    final latestMessages = await SupabaseConfig.client
        .from('chat_messages')
        .select('message, created_at')
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(1);

    final latest = latestMessages.isEmpty
        ? null
        : Map<String, dynamic>.from(latestMessages.first as Map);

    await SupabaseConfig.client
        .from('chat_rooms')
        .update({
          'last_message': latest == null
              ? 'Mulai percakapan'
              : previewText(latest['message']?.toString() ?? ''),
          'last_message_at':
              latest?['created_at']?.toString() ??
              DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
    _roomsCache.clear();
  }

  static void clearCache() => _roomsCache.clear();

  void _invalidateUsers(int buyerId, int sellerId) {
    _roomsCache.remove(buyerId);
    _roomsCache.remove(sellerId);
  }

  Map<String, dynamic> _mapRoom(dynamic row) {
    final room = Map<String, dynamic>.from(row as Map);
    room['products'] = Map<String, dynamic>.from(
      (room['products'] as Map?) ?? {},
    );
    if (room['buyer'] is Map) {
      room['buyer'] = Map<String, dynamic>.from(room['buyer'] as Map);
    }
    if (room['seller'] is Map) {
      room['seller'] = Map<String, dynamic>.from(room['seller'] as Map);
    }
    return room;
  }

  List<Map<String, dynamic>> _cloneList(List<Map<String, dynamic>> rooms) {
    return rooms.map((room) {
      final clone = Map<String, dynamic>.from(room);
      if (clone['products'] is Map) {
        clone['products'] = Map<String, dynamic>.from(clone['products'] as Map);
      }
      if (clone['buyer'] is Map) {
        clone['buyer'] = Map<String, dynamic>.from(clone['buyer'] as Map);
      }
      if (clone['seller'] is Map) {
        clone['seller'] = Map<String, dynamic>.from(clone['seller'] as Map);
      }
      return clone;
    }).toList();
  }
}

class _ChatRoomsCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> rooms;

  _ChatRoomsCacheEntry(this.rooms) : createdAt = DateTime.now();
}
