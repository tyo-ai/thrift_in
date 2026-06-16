import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/skeleton_loaders.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'saved_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'live_bidding_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = ProductService.defaultPageSize;

  int _selectedCategory = 0;
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'Semua',
    'Pakaian',
    'Sepatu',
    'Aksesoris',
    'Tas',
    'Elektronik',
  ];

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _liveProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadProducts();
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _hasMore = true;
        _offset = 0;
      });

      final service = ProductService();
      final liveProducts = await service.getLiveProducts(
        limit: 6,
        forceRefresh: forceRefresh,
      );
      final products = await service.getProducts(
        limit: _pageSize,
        offset: 0,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _liveProducts = liveProducts;
        _allProducts = products;
        _hasMore = products.length == _pageSize;
        _offset = products.length;
        _isLoading = false;
      });
      _filterProducts();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allProducts = [];
        _products = [];
        _liveProducts = [];
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final products = await ProductService().getProducts(
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _allProducts.addAll(products);
        _offset += products.length;
        _hasMore = products.length == _pageSize;
        _isLoadingMore = false;
      });
      _filterProducts();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _handleScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      _loadMoreProducts();
    }
  }

  Future<void> _refreshFavorites() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    try {
      final favorites = await ProductService().getFavoriteProducts(forceRefresh: true);
      final favoriteIds = favorites
          .map((p) => int.tryParse(p['id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();

      if (!mounted) return;

      setState(() {
        for (var i = 0; i < _allProducts.length; i++) {
          final id = int.tryParse(_allProducts[i]['id']?.toString() ?? '');
          _allProducts[i]['isFavorite'] = (id != null && favoriteIds.contains(id)) ? 1 : 0;
        }
        for (var i = 0; i < _liveProducts.length; i++) {
          final id = int.tryParse(_liveProducts[i]['id']?.toString() ?? '');
          _liveProducts[i]['isFavorite'] = (id != null && favoriteIds.contains(id)) ? 1 : 0;
        }
        _filterProducts();
      });
    } catch (_) {
      // Ignore errors during silent refresh
    }
  }

  Future<void> _navigateToProductDetail(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    await _refreshFavorites();
  }

  void _filterProducts() {
    if (_selectedCategory == 0) {
      setState(() {
        _products = List.from(_allProducts);
      });
    } else {
      final cat = _categories[_selectedCategory];
      setState(() {
        _products = _allProducts.where((p) => p['category'] == cat).toList();
      });
    }
  }

  String _text(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Rp 0';

    final text = value.toString();

    if (text.toLowerCase().startsWith('rp')) {
      return text;
    }

    final onlyNumber = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (onlyNumber.isEmpty) {
      return 'Rp 0';
    }

    final formatted = onlyNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 54,
        leadingWidth: 44,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: AppColors.primary, size: 22),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'ThriftIn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadProducts(forceRefresh: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              if (!_isLoading && _liveProducts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildLiveBadge(),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSectionTitle(),
                ),
                const SizedBox(height: 10),
                _buildLiveBiddingList(),
                const SizedBox(height: 18),
              ],

              _buildCategoryTabs(),

              const SizedBox(height: 16),

              _isLoading ? SkeletonLoaders.productGrid() : _buildProductGrid(),

              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4DE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: Color(0xFFFF5A3D)),
          SizedBox(width: 5),
          Text(
            'Lelang Sedang Berlangsung',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF5A3D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Live Bidding',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveBiddingScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(20, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBiddingList() {
    final liveProducts = _liveProducts.take(6).toList();

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: liveProducts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = liveProducts[index];
          return _buildLiveAuctionCard(product);
        },
      ),
    );
  }

  Widget _buildLiveAuctionCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE6EDF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(
                  _text(product['imageUrl'], ''),
                  height: 130,
                  width: double.infinity,
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gavel_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Live Bid',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _text(product['name'], 'Produk Lelang'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2CF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Bid',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB96C00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatPrice(product['price']),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _navigateToProductDetail(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Bid',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = index);
                _filterProducts();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE0E7EF),
                  ),
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Center(
          child: Text(
            'Belum ada produk.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];

          return GestureDetector(
            onTap: () => _navigateToProductDetail(product),
            child: _buildProductCard(product, index),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final isFavorite =
        product['isFavorite'] == 1 || product['isFavorite'] == true;

    Future<void> toggleFavorite() async {
      final newValue = !isFavorite;
      final productId = product['id'];

      setState(() {
        _products[index] = Map<String, dynamic>.from(product)
          ..['isFavorite'] = newValue ? 1 : 0;

        if (productId != null) {
          final rawIdx = _allProducts.indexWhere((p) => p['id'] == productId);
          if (rawIdx != -1) {
            _allProducts[rawIdx] = Map<String, dynamic>.from(
              _allProducts[rawIdx],
            )..['isFavorite'] = newValue ? 1 : 0;
          }
        }
      });

      final parsedId = productId is int
          ? productId
          : int.tryParse(productId?.toString() ?? '');
      if (parsedId != null) {
        await ProductService().toggleFavorite(parsedId, newValue);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _buildImage(
                  _text(product['imageUrl'], ''),
                  width: double.infinity,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: toggleFavorite,
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.red : AppColors.textSecondary,
                      size: 17,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: _buildMiniTag(
                  product['isBid'] == 1 || product['isBid'] == true
                      ? 'Lelang'
                      : _text(product['badge'], 'Tersedia'),
                  orange: product['isBid'] == 1 || product['isBid'] == true,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              _text(product['name'], 'Nama Produk'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    _text(product['location'], 'Lokasi belum diisi'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
            child: _buildProductMeta(product),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Text(
              _formatPrice(product['price']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String text, {bool orange = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: orange
            ? const Color(0xFFFFF1C2).withValues(alpha: 0.95)
            : AppColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: orange ? const Color(0xFF8A5200) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductMeta(Map<String, dynamic> product) {
    final rating = double.tryParse(product['rating']?.toString() ?? '') ?? 0;
    final reviewCount =
        int.tryParse(product['reviewCount']?.toString() ?? '') ?? 0;
    final hasRating = rating > 0 && reviewCount > 0;

    return Row(
      children: [
        if (hasRating) ...[
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
          const SizedBox(width: 3),
          Text(
            '${rating.toStringAsFixed(1)} ($reviewCount)',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else
          const Text(
            'Belum ada rating',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String imageUrl, {required double width, double? height}) {
    if (imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder(height: height ?? 150, width: width);
    }

    if (imageUrl.startsWith('assets/')) {
      return SizedBox(
        width: width,
        child: Image.asset(
          imageUrl,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return _buildImagePlaceholder(height: height ?? 150, width: width);
          },
        ),
      );
    }

    return CachedProductImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: 420,
    );
  }

  Widget _buildImagePlaceholder({
    required double height,
    required double width,
  }) {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFEFF3F6),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 34,
      ),
    );
  }
}
