import 'supabase_config.dart';

class ChatService {
  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<int, _ChatRoomsCacheEntry> _roomsCache = {};

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

    final room = await SupabaseConfig.client
        .from('chat_rooms')
        .insert({
          'product_id': productId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'created_at': DateTime.now().toIso8601String(),
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
    await SupabaseConfig.client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'message': message,
      'offer_amount': offerAmount,
      'created_at': now,
    });

    await SupabaseConfig.client
        .from('chat_rooms')
        .update({
          'last_message': offerAmount == null
              ? message
              : 'Menawarkan Rp $offerAmount',
          'last_message_at': now,
        })
        .eq('id', roomId);
    _roomsCache.clear();
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
