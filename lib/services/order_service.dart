import 'package:shared_preferences/shared_preferences.dart';

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
    await markOrderAsOpened(orderId, buyerId, sellerMode: false);

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
    final orders = await _withOpenedState(
      _mapOrders(results, sellerKey: 'seller').reversed.toList(),
      buyerId,
      sellerMode: false,
    );
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
    final orders = await _withOpenedState(
      _mapOrders(results, buyerKey: 'buyer').reversed.toList(),
      sellerId,
      sellerMode: true,
    );
    _writeCache(cacheKey, orders);
    return _cloneList(orders);
  }

  Future<int> getUnopenedOrdersCount(
    int userId, {
    required bool sellerMode,
    bool forceRefresh = false,
  }) async {
    final orders = sellerMode
        ? await getOrdersBySeller(userId, forceRefresh: forceRefresh)
        : await getOrdersByBuyer(userId, forceRefresh: forceRefresh);
    return orders.where((order) => order['is_opened'] != true).length;
  }

  Future<int> getTotalUnopenedOrdersCount(
    int userId, {
    bool forceRefresh = false,
  }) async {
    final buyerCount = await getUnopenedOrdersCount(
      userId,
      sellerMode: false,
      forceRefresh: forceRefresh,
    );
    final sellerCount = await getUnopenedOrdersCount(
      userId,
      sellerMode: true,
      forceRefresh: forceRefresh,
    );
    return buyerCount + sellerCount;
  }

  Future<void> markOrderAsOpened(
    int orderId,
    int userId, {
    required bool sellerMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _openedOrdersKey(userId, sellerMode: sellerMode);
    final opened = prefs.getStringList(key) ?? const <String>[];
    final id = orderId.toString();
    if (opened.contains(id)) return;
    await prefs.setStringList(key, [...opened, id]);
    _markCachedOrderAsOpened(userId, orderId, sellerMode: sellerMode);
  }

  Future<bool> isOrderOpened(
    int orderId,
    int userId, {
    required bool sellerMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final opened =
        prefs.getStringList(_openedOrdersKey(userId, sellerMode: sellerMode)) ??
        const <String>[];
    return opened.contains(orderId.toString());
  }

  Future<int> updateOrderStatus(
    int orderId,
    String newStatus, {
    int? sellerId,
  }) async {
    final updateQuery = SupabaseConfig.client
        .from('orders')
        .update({'status': newStatus})
        .eq('id', orderId);

    if (sellerId != null) {
      await updateQuery.eq('seller_id', sellerId);
    } else {
      await updateQuery;
    }

    final selectQuery = SupabaseConfig.client
        .from('orders')
        .select('buyer_id, seller_id')
        .eq('id', orderId);

    final order = sellerId != null
        ? await selectQuery.eq('seller_id', sellerId).maybeSingle()
        : await selectQuery.maybeSingle();
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

  Future<SalesReport> getSalesReport(int sellerId) async {
    final orders = await getOrdersBySeller(sellerId, forceRefresh: true);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );
    final monthStart = DateTime(now.year, now.month);

    final completed = orders.where((order) {
      return order['status']?.toString() == 'Selesai';
    }).toList();

    return SalesReport(
      today: _summarizePeriod(completed, todayStart, tomorrowStart),
      week: _summarizePeriod(completed, weekStart, tomorrowStart),
      month: _summarizePeriod(completed, monthStart, tomorrowStart),
      transactions: orders,
    );
  }

  static void clearCache() => _cache.clear();

  void _invalidateUserCaches(int buyerId, int sellerId) {
    _cache.remove('buyer:$buyerId');
    _cache.remove('seller:$sellerId');
  }

  SalesReportSummary _summarizePeriod(
    List<Map<String, dynamic>> orders,
    DateTime start,
    DateTime end,
  ) {
    final periodOrders = orders.where((order) {
      final date = DateTime.tryParse(order['created_at']?.toString() ?? '');
      if (date == null) return false;
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();

    final revenue = periodOrders.fold<int>(0, (sum, order) {
      return sum + (int.tryParse(order['total_amount']?.toString() ?? '') ?? 0);
    });

    return SalesReportSummary(
      completedOrders: periodOrders.length,
      soldItems: periodOrders.length,
      revenue: revenue,
    );
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

  Future<List<Map<String, dynamic>>> _withOpenedState(
    List<Map<String, dynamic>> orders,
    int userId, {
    required bool sellerMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final opened =
        prefs.getStringList(_openedOrdersKey(userId, sellerMode: sellerMode)) ??
        const <String>[];
    return orders.map((order) {
      final mapped = Map<String, dynamic>.from(order);
      mapped['is_opened'] = opened.contains(mapped['id']?.toString());
      return mapped;
    }).toList();
  }

  void _markCachedOrderAsOpened(
    int userId,
    int orderId, {
    required bool sellerMode,
  }) {
    final key = sellerMode ? 'seller:$userId' : 'buyer:$userId';
    final cached = _cache[key];
    if (cached == null) return;
    for (final order in cached.orders) {
      if (order['id']?.toString() == orderId.toString()) {
        order['is_opened'] = true;
      }
    }
  }

  String _openedOrdersKey(int userId, {required bool sellerMode}) {
    final mode = sellerMode ? 'seller' : 'buyer';
    return 'opened_orders_${mode}_$userId';
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

class SalesReport {
  final SalesReportSummary today;
  final SalesReportSummary week;
  final SalesReportSummary month;
  final List<Map<String, dynamic>> transactions;

  SalesReport({
    required this.today,
    required this.week,
    required this.month,
    required this.transactions,
  });
}

class SalesReportSummary {
  final int completedOrders;
  final int soldItems;
  final int revenue;

  SalesReportSummary({
    required this.completedOrders,
    required this.soldItems,
    required this.revenue,
  });
}

class _OrderCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> orders;

  _OrderCacheEntry(this.orders) : createdAt = DateTime.now();
}
