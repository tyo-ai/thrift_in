import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'user_service.dart';

class ProductService {
  static const int defaultPageSize = 20;
  static const Duration _cacheTtl = Duration(minutes: 2);
  static final Map<String, _ProductCacheEntry> _cache = {};

  Future<List<Map<String, dynamic>>> getProducts({
    int limit = defaultPageSize,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'products:${UserService.currentUserId}:$limit:$offset';
    final cached = _readCache(cacheKey, forceRefresh: forceRefresh);
    if (cached != null) return cached;

    final results = await SupabaseConfig.client
        .from('products')
        .select('*, product_images(*)')
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
    final products = await _withFavorites(_mapList(results));
    _writeCache(cacheKey, products);
    return _cloneList(products);
  }

  Future<List<Map<String, dynamic>>> getProductsBySeller(
    int sellerId, {
    int limit = defaultPageSize,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'seller:$sellerId:${UserService.currentUserId}:$limit:$offset';
    final cached = _readCache(cacheKey, forceRefresh: forceRefresh);
    if (cached != null) return cached;

    final results = await SupabaseConfig.client
        .from('products')
        .select('*, product_images(*)')
        .eq('seller_id', sellerId)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
    final products = await _withFavorites(_mapList(results));
    _writeCache(cacheKey, products);
    return _cloneList(products);
  }

  Future<List<Map<String, dynamic>>> getLiveProducts({
    int limit = defaultPageSize,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'live:${UserService.currentUserId}:$limit:$offset';
    final cached = _readCache(cacheKey, forceRefresh: forceRefresh);
    if (cached != null) return cached;

    final results = await SupabaseConfig.client
        .from('products')
        .select('*, product_images(*)')
        .eq('isBid', 1)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
    final products = await _withFavorites(_mapList(results));
    _writeCache(cacheKey, products);
    return _cloneList(products);
  }

  Future<List<Map<String, dynamic>>> searchProducts(
    String query, {
    int limit = defaultPageSize,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return getProducts(
        limit: limit,
        offset: offset,
        forceRefresh: forceRefresh,
      );
    }

    final cacheKey =
        'search:${UserService.currentUserId}:$trimmedQuery:$limit:$offset';
    final cached = _readCache(cacheKey, forceRefresh: forceRefresh);
    if (cached != null) return cached;

    final searchTerm = trimmedQuery.toLowerCase() == 'jacket'
        ? 'jaket'
        : trimmedQuery;
    final escaped = searchTerm.replaceAll(',', ' ');
    final results = await SupabaseConfig.client
        .from('products')
        .select('*, product_images(*)')
        .or(
          'name.ilike.%$escaped%,category.ilike.%$escaped%,condition.ilike.%$escaped%,storeName.ilike.%$escaped%,location.ilike.%$escaped%',
        )
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    final products = await _withFavorites(_mapList(results));
    final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
    if (terms.isEmpty) return products;

    final filtered = products.where((product) {
      final searchable = [
        product['name'],
        product['category'],
        product['condition'],
        product['storeName'],
        product['location'],
      ].join(' ').toLowerCase();

      return terms.every((term) {
        if (term == 'jacket') {
          return searchable.contains('jaket') ||
              searchable.contains('jacket') ||
              searchable.contains('pakaian');
        }
        return searchable.contains(term);
      });
    }).toList();

    _writeCache(cacheKey, filtered);
    return _cloneList(filtered);
  }

  Future<int> addProduct({
    required int sellerId,
    required String name,
    required String price,
    double rating = 0.0,
    int reviewCount = 0,
    String category = 'Semua',
    String condition = 'Pernah Dipakai',
    required String storeName,
    required String location,
    required String imageUrl,
    String? badge,
    bool isBid = false,
    String? endTime,
    String? description,
    List<String> imageUrls = const [],
  }) async {
    final urls = imageUrls.isEmpty ? [imageUrl] : imageUrls;
    final hasInvalidUrl = urls.any((url) => !_isRemoteImageUrl(url));
    if (!_isRemoteImageUrl(imageUrl) || hasInvalidUrl) {
      throw ArgumentError(
        'Foto produk harus berupa URL publik dari Supabase Storage.',
      );
    }

    final result = await SupabaseConfig.client
        .from('products')
        .insert({
          'seller_id': sellerId,
          'name': name,
          'price': price,
          'rating': rating,
          'reviewCount': reviewCount,
          'category': category,
          'condition': condition,
          'storeName': storeName,
          'location': location,
          'imageUrl': imageUrl,
          'isFavorite': 0,
          'badge': badge,
          'isBid': isBid ? 1 : 0,
          'end_time': endTime,
          'description': description ?? 'Tidak ada deskripsi produk.',
        })
        .select('id')
        .single();
    final productId = result['id'] as int;

    await SupabaseConfig.client
        .from('product_images')
        .insert(
          urls.asMap().entries.map((entry) {
            return {
              'product_id': productId,
              'image_url': entry.value,
              'sort_order': entry.key,
              'created_at': DateTime.now().toIso8601String(),
            };
          }).toList(),
        );

    clearCache();
    return productId;
  }

  Future<String> uploadProductImage({
    required File imageFile,
    required int sellerId,
    required int index,
  }) async {
    if (!await imageFile.exists()) {
      throw ArgumentError('File foto produk tidak ditemukan.');
    }

    final extension = imageFile.path.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final objectPath =
        '$sellerId/${DateTime.now().microsecondsSinceEpoch}_$index.$safeExtension';

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

  bool _isRemoteImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts({
    bool forceRefresh = false,
  }) async {
    final userId = UserService.currentUserId;
    if (userId == null) return [];

    final cacheKey = 'favorites:$userId';
    final cached = _readCache(cacheKey, forceRefresh: forceRefresh);
    if (cached != null) return cached;

    final results = await SupabaseConfig.client
        .from('user_favorites')
        .select('products(*, product_images(*))')
        .eq('user_id', userId)
        .order('created_at');

    final products = results.map((row) {
      final favorite = Map<String, dynamic>.from(row as Map);
      final product = Map<String, dynamic>.from(
        (favorite['products'] as Map?) ?? {},
      );
      return _normalizeProduct(product)..['isFavorite'] = 1;
    }).toList();

    final favorites = products.reversed.toList();
    _writeCache(cacheKey, favorites);
    return _cloneList(favorites);
  }

  Future<int> toggleFavorite(int id, bool isFav) async {
    final userId = UserService.currentUserId;
    if (userId == null) return 0;

    if (isFav) {
      await SupabaseConfig.client.from('user_favorites').upsert({
        'user_id': userId,
        'product_id': id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await SupabaseConfig.client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', id);
    }
    clearCache();
    return 1;
  }

  Future<int> deleteProduct(int id, {int? sellerId}) async {
    var query = SupabaseConfig.client.from('products').delete().eq('id', id);
    if (sellerId != null) {
      query = query.eq('seller_id', sellerId);
    }

    await query;
    clearCache();
    return 1;
  }

  static void clearCache() {
    _cache.clear();
  }

  List<Map<String, dynamic>> _mapList(List<dynamic> rows) {
    return rows
        .map((row) => _normalizeProduct(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _withFavorites(
    List<Map<String, dynamic>> products,
  ) async {
    final userId = UserService.currentUserId;
    if (userId == null || products.isEmpty) return products;

    final ids = products
        .map((product) => int.tryParse(product['id']?.toString() ?? ''))
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return products;

    final favorites = await SupabaseConfig.client
        .from('user_favorites')
        .select('product_id')
        .eq('user_id', userId)
        .inFilter('product_id', ids);

    final favoriteIds = favorites
        .map((row) => (row as Map)['product_id'])
        .whereType<int>()
        .toSet();

    return products.map((product) {
      final productId = int.tryParse(product['id']?.toString() ?? '');
      return product
        ..['isFavorite'] = productId != null && favoriteIds.contains(productId)
            ? 1
            : 0;
    }).toList();
  }

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

  List<Map<String, dynamic>>? _readCache(
    String key, {
    bool forceRefresh = false,
  }) {
    if (forceRefresh) return null;
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.createdAt) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return _cloneList(entry.items);
  }

  void _writeCache(String key, List<Map<String, dynamic>> items) {
    _cache[key] = _ProductCacheEntry(_cloneList(items));
  }

  List<Map<String, dynamic>> _cloneList(List<Map<String, dynamic>> items) {
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}

class _ProductCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;

  _ProductCacheEntry(this.items) : createdAt = DateTime.now();
}
