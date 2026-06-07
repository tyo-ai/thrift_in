import 'supabase_config.dart';
import 'user_service.dart';

class CartService {
  static const Duration _cacheTtl = Duration(minutes: 2);
  static final Map<int, _CartCacheEntry> _cache = {};

  Future<List<Map<String, dynamic>>> getCartItems({
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
        .from('cart_items')
        .select('quantity, created_at, products(*, product_images(*))')
        .eq('user_id', userId)
        .order('created_at');

    final items = results.map((row) {
      final cartItem = Map<String, dynamic>.from(row as Map);
      final product = Map<String, dynamic>.from(
        (cartItem['products'] as Map?) ?? {},
      );

      return {
        'quantity': cartItem['quantity'] ?? 1,
        'created_at': cartItem['created_at'],
        'product': _normalizeProduct(product),
      };
    }).toList();

    final cartItems = items.reversed.toList();
    _cache[userId] = _CartCacheEntry(_cloneList(cartItems));
    return _cloneList(cartItems);
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    final userId = UserService.currentUserId;
    if (userId == null) {
      throw Exception('Silakan login terlebih dahulu');
    }

    await SupabaseConfig.client.from('cart_items').upsert({
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,product_id');
    _cache.remove(userId);
  }

  Future<void> removeFromCart(int productId) async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    await SupabaseConfig.client
        .from('cart_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
    _cache.remove(userId);
  }

  Future<void> clearCart() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    await SupabaseConfig.client
        .from('cart_items')
        .delete()
        .eq('user_id', userId);
    _cache.remove(userId);
  }

  static void clearCache() => _cache.clear();

  Map<String, dynamic> _normalizeProduct(Map<String, dynamic> product) {
    final images =
        ((product['product_images'] as List?) ?? [])
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList()
          ..sort((a, b) {
            final aOrder = int.tryParse(a['sort_order']?.toString() ?? '') ?? 0;
            final bOrder = int.tryParse(b['sort_order']?.toString() ?? '') ?? 0;
            return aOrder.compareTo(bOrder);
          });

    if (images.isNotEmpty) {
      product['images'] = images.map((image) => image['image_url']).toList();
      final firstUrl = images.first['image_url']?.toString();
      if (firstUrl != null && firstUrl.isNotEmpty) {
        product['imageUrl'] = firstUrl;
      }
    }

    product['isFavorite'] = product['isFavorite'] == 1 ? 1 : 0;
    return product;
  }

  List<Map<String, dynamic>> _cloneList(List<Map<String, dynamic>> items) {
    return items.map((item) {
      final clone = Map<String, dynamic>.from(item);
      if (clone['product'] is Map) {
        clone['product'] = Map<String, dynamic>.from(clone['product'] as Map);
      }
      return clone;
    }).toList();
  }
}

class _CartCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;

  _CartCacheEntry(this.items) : createdAt = DateTime.now();
}
