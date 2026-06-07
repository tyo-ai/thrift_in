import 'supabase_config.dart';
import 'notification_service.dart';

class BidService {
  static const Duration _cacheTtl = Duration(seconds: 20);
  static final Map<int, _BidCacheEntry> _bidsCache = {};
  static final Map<int, _HighestBidCacheEntry> _highestBidCache = {};

  Future<int> placeBid({
    required int productId,
    required int buyerId,
    required int amount,
  }) async {
    final result = await SupabaseConfig.client
        .from('bids')
        .insert({
          'product_id': productId,
          'buyer_id': buyerId,
          'amount': amount,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final product = await SupabaseConfig.client
        .from('products')
        .select('name, seller_id')
        .eq('id', productId)
        .maybeSingle();
    if (product != null && product['seller_id'] != buyerId) {
      await NotificationService().createNotification(
        userId: product['seller_id'] as int,
        title: 'Tawaran baru masuk',
        description: 'Produk ${product['name']} menerima tawaran Rp $amount.',
        iconName: 'gavel',
        iconColorHex: 'FFF59E0B',
        iconBgColorHex: 'FFFFF3E0',
      );
    }

    _bidsCache.remove(productId);
    _highestBidCache.remove(productId);
    return result['id'] as int;
  }

  Future<List<Map<String, dynamic>>> getBidsForItem(int productId) async {
    final cached = _bidsCache[productId];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return cached.bids.map((bid) => Map<String, dynamic>.from(bid)).toList();
    }

    final results = await SupabaseConfig.client
        .from('bids')
        .select('*, users(name)')
        .eq('product_id', productId)
        .order('amount', ascending: false)
        .order('id');

    final bids = results.map((row) {
      final bid = Map<String, dynamic>.from(row as Map);
      final user = Map<String, dynamic>.from((bid['users'] as Map?) ?? {});
      bid['buyer_name'] = user['name'];
      return bid;
    }).toList();
    _bidsCache[productId] = _BidCacheEntry(bids);
    return bids.map((bid) => Map<String, dynamic>.from(bid)).toList();
  }

  Future<int> getHighestBid(int productId) async {
    final cached = _highestBidCache[productId];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return cached.amount;
    }

    final results = await SupabaseConfig.client
        .from('bids')
        .select('amount')
        .eq('product_id', productId)
        .order('amount', ascending: false)
        .limit(1);

    final amount = results.isEmpty
        ? 0
        : (results.first['amount'] as num).toInt();
    _highestBidCache[productId] = _HighestBidCacheEntry(amount);
    return amount;
  }
}

class _BidCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> bids;

  _BidCacheEntry(this.bids) : createdAt = DateTime.now();
}

class _HighestBidCacheEntry {
  final DateTime createdAt;
  final int amount;

  _HighestBidCacheEntry(this.amount) : createdAt = DateTime.now();
}
