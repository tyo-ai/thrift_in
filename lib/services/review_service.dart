import 'supabase_config.dart';

class ReviewService {
  static const Duration _cacheTtl = Duration(minutes: 3);
  static final Map<int, _ReviewListCacheEntry> _productReviewCache = {};
  static final Map<int, _ReviewSummaryCacheEntry> _sellerSummaryCache = {};

  Future<List<Map<String, dynamic>>> getReviewsForProduct(
    int productId, {
    bool forceRefresh = false,
  }) async {
    final cached = _productReviewCache[productId];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return _cloneList(cached.reviews);
    }

    final results = await SupabaseConfig.client
        .from('reviews')
        .select('*, users!reviews_reviewer_id_fkey(name, photo_path)')
        .eq('product_id', productId)
        .order('id', ascending: false);

    final reviews = results.map((row) {
      final review = Map<String, dynamic>.from(row as Map);
      final user = Map<String, dynamic>.from((review['users'] as Map?) ?? {});
      review['reviewer_name'] = user['name'] ?? 'Pembeli';
      review['reviewer_photo_path'] = user['photo_path'];
      return review;
    }).toList();

    _productReviewCache[productId] = _ReviewListCacheEntry(_cloneList(reviews));
    return _cloneList(reviews);
  }

  Future<Map<String, dynamic>> getSellerReviewSummary(
    int sellerId, {
    bool forceRefresh = false,
  }) async {
    final cached = _sellerSummaryCache[sellerId];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) < _cacheTtl) {
      return Map<String, dynamic>.from(cached.summary);
    }

    final results = await SupabaseConfig.client
        .from('reviews')
        .select('rating')
        .eq('seller_id', sellerId);

    if (results.isEmpty) {
      const summary = {'average': 0.0, 'count': 0};
      _sellerSummaryCache[sellerId] = _ReviewSummaryCacheEntry(summary);
      return Map<String, dynamic>.from(summary);
    }

    final ratings = results
        .map((row) => ((row as Map)['rating'] as num).toDouble())
        .toList();
    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    final summary = {
      'average': double.parse(average.toStringAsFixed(1)),
      'count': ratings.length,
    };
    _sellerSummaryCache[sellerId] = _ReviewSummaryCacheEntry(summary);
    return Map<String, dynamic>.from(summary);
  }

  Future<List<Map<String, dynamic>>> getReviewsForSeller(
    int sellerId, {
    bool forceRefresh = false,
  }) async {
    final results = await SupabaseConfig.client
        .from('reviews')
        .select(
          '*, products(name, imageUrl), users!reviews_reviewer_id_fkey(name, photo_path)',
        )
        .eq('seller_id', sellerId)
        .order('id', ascending: false);

    return results.map((row) {
      final review = Map<String, dynamic>.from(row as Map);
      final user = Map<String, dynamic>.from((review['users'] as Map?) ?? {});
      final product = Map<String, dynamic>.from(
        (review['products'] as Map?) ?? {},
      );
      review['reviewer_name'] = user['name'] ?? 'Pembeli';
      review['reviewer_photo_path'] = user['photo_path'];
      review['product_name'] = product['name'] ?? 'Produk';
      review['product_image'] = product['imageUrl'];
      return review;
    }).toList();
  }

  Future<int> addReview({
    required int productId,
    required int orderId,
    required int reviewerId,
    required int sellerId,
    required int rating,
    String? comment,
  }) async {
    final result = await SupabaseConfig.client
        .from('reviews')
        .upsert({
          'product_id': productId,
          'order_id': orderId,
          'reviewer_id': reviewerId,
          'seller_id': sellerId,
          'rating': rating,
          'comment': comment,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'order_id,reviewer_id')
        .select('id')
        .single();

    await _refreshProductRating(productId);
    _productReviewCache.remove(productId);
    _sellerSummaryCache.remove(sellerId);
    return result['id'] as int;
  }

  static void clearCache() {
    _productReviewCache.clear();
    _sellerSummaryCache.clear();
  }

  Future<void> _refreshProductRating(int productId) async {
    final reviews = await SupabaseConfig.client
        .from('reviews')
        .select('rating')
        .eq('product_id', productId);

    if (reviews.isEmpty) return;

    final ratings = reviews
        .map((row) => ((row as Map)['rating'] as num).toDouble())
        .toList();
    final average = ratings.reduce((a, b) => a + b) / ratings.length;

    await SupabaseConfig.client
        .from('products')
        .update({
          'rating': double.parse(average.toStringAsFixed(1)),
          'reviewCount': ratings.length,
        })
        .eq('id', productId);
  }

  List<Map<String, dynamic>> _cloneList(List<Map<String, dynamic>> items) {
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}

class _ReviewListCacheEntry {
  final DateTime createdAt;
  final List<Map<String, dynamic>> reviews;

  _ReviewListCacheEntry(this.reviews) : createdAt = DateTime.now();
}

class _ReviewSummaryCacheEntry {
  final DateTime createdAt;
  final Map<String, dynamic> summary;

  _ReviewSummaryCacheEntry(this.summary) : createdAt = DateTime.now();
}
