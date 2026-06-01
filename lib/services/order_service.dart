import 'supabase_config.dart';
import 'notification_service.dart';

class OrderService {
  static const Duration _cacheTtl = Duration(minutes: 2);
  static final Map<String, _OrderCacheEntry> _cache = {};

  Future<int> createOrder({
    required int productId,
    required int buyerId,
    required int sellerId,
    required int totalAmount,
    required String paymentMethod,
    String status = 'Menunggu',
    String? shippingAddress,
    String shippingMethod = 'EcoExpress',
    int shippingCost = 0,
    int serviceFee = 0,
    int discount = 0,
  }) async {
    final result = await SupabaseConfig.client
        .from('orders')
        .insert({
          'product_id': productId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'total_amount': totalAmount,
          'status': status,
          'payment_method': paymentMethod,
          'shipping_address': shippingAddress,
          'shipping_method': shippingMethod,
          'shipping_cost': shippingCost,
          'service_fee': serviceFee,
          'discount': discount,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    final orderId = result['id'] as int;

    await NotificationService().createNotification(
      userId: sellerId,
      title: 'Pesanan baru',
      description: 'Pesanan baru masuk dengan total Rp $totalAmount.',
      iconName: 'check_circle',
      iconColorHex: 'FF0D5C37',
      iconBgColorHex: 'FFE8F5EE',
    );

    _invalidateUserCaches(buyerId, sellerId);
    return orderId;
  }

  Future<List<Map<String, dynamic>>> getOrdersByBuyer(
    int buyerId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'buyer:$buyerId';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    final results = await SupabaseConfig.client
        .from('orders')
        .select(
          '*, products(name, imageUrl), seller:users!orders_seller_id_fkey(name)',
        )
        .eq('buyer_id', buyerId)
        .order('id');
    final orders = _mapOrders(results, sellerKey: 'seller').reversed.toList();
    _writeCache(cacheKey, orders);
    return _cloneList(orders);
  }

  Future<List<Map<String, dynamic>>> getOrdersBySeller(
    int sellerId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'seller:$sellerId';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    final results = await SupabaseConfig.client
        .from('orders')
        .select(
          '*, products(name, imageUrl), buyer:users!orders_buyer_id_fkey(name)',
        )
        .eq('seller_id', sellerId)
        .order('id');
    final orders = _mapOrders(results, buyerKey: 'buyer').reversed.toList();
    _writeCache(cacheKey, orders);
    return _cloneList(orders);
  }

  Future<int> updateOrderStatus(int orderId, String newStatus) async {
    await SupabaseConfig.client
        .from('orders')
        .update({'status': newStatus})
        .eq('id', orderId);

    final order = await SupabaseConfig.client
        .from('orders')
        .select('buyer_id, seller_id')
        .eq('id', orderId)
        .maybeSingle();
    if (order != null) {
      await NotificationService().createNotification(
        userId: order['buyer_id'] as int,
        title: 'Status pesanan diperbarui',
        description: 'Pesanan #$orderId sekarang berstatus $newStatus.',
        iconName: 'local_fire_department',
        iconColorHex: 'FF1976D2',
        iconBgColorHex: 'FFE3F2FD',
      );
      _invalidateUserCaches(
        order['buyer_id'] as int,
        order['seller_id'] as int,
      );
    }
    return 1;
  }

  Future<int> deleteOrder(int orderId) async {
    final order = await SupabaseConfig.client
        .from('orders')
        .select('buyer_id, seller_id')
        .eq('id', orderId)
        .maybeSingle();
    await SupabaseConfig.client.from('orders').delete().eq('id', orderId);
    if (order != null) {
      _invalidateUserCaches(
        order['buyer_id'] as int,
        order['seller_id'] as int,
      );
    } else {
      _cache.clear();
    }
    return 1;
  }

  static void clearCache() => _cache.clear();

  void _invalidateUserCaches(int buyerId, int sellerId) {
    _cache.remove('buyer:$buyerId');
    _cache.remove('seller:$sellerId');
  }

  List<Map<String, dynamic>>? _readCache(String key, bool forceRefresh) {
    if (forceRefresh) return null;
    final cached = _cache[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.createdAt) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return _cloneList(cached.orders);
  }

  void _writeCache(String key, List<Map<String, dynamic>> orders) {
    _cache[key] = _OrderCacheEntry(_cloneList(orders));
  }

  List<Map<String, dynamic>> _mapOrders(
    List<dynamic> rows, {
    String? sellerKey,
    String? buyerKey,
  }) {
    return rows.map((row) {
      final order = Map<String, dynamic>.from(row as Map);
      final product = Map<String, dynamic>.from(
        (order['products'] as Map?) ?? {},
      );
      final seller = Map<String, dynamic>.from(
        (order[sellerKey] as Map?) ?? {},
      );
      final buyer = Map<String, dynamic>.from((order[buyerKey] as Map?) ?? {});

      order['product_name'] = product['name'];
      order['product_image'] = product['imageUrl'];
      if (sellerKey != null) order['seller_name'] = seller['name'];
      if (buyerKey != null) order['buyer_name'] = buyer['name'];
      return order;
    }).toList();
  }

  List<Map<String, dynamic>> _cloneList(List<Map<String, dynamic>> items) {
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}

class _OrderCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> orders;

  _OrderCacheEntry(this.orders) : createdAt = DateTime.now();
}
