import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/user_avatar.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/review_service.dart';
import 'settings_screen.dart';
import 'saved_screen.dart';
import 'cart_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _userName => UserService.currentUser?['name'] ?? 'Andhika';
  String get _userBio {
    final bio = UserService.currentUser?['bio']?.toString().trim();
    return (bio == null || bio.isEmpty)
        ? 'Lengkapi profilmu agar tampil lebih menarik di ThriftIn'
        : bio;
  }

  bool get _hasBio {
    final bio = UserService.currentUser?['bio']?.toString().trim();
    return bio != null && bio.isNotEmpty;
  }

  List<Map<String, dynamic>> _myItems = [];
  List<Map<String, dynamic>> _sellerReviews = [];
  int _sellerUnopenedOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (UserService.currentUserId != null) {
        final userId = UserService.currentUserId!;
        final items = await ProductService().getProductsBySeller(userId);
        final reviews = await ReviewService().getReviewsForSeller(
          userId,
          forceRefresh: true,
        );
        final sellerUnopenedOrders = await OrderService()
            .getUnopenedOrdersCount(
              userId,
              sellerMode: true,
              forceRefresh: true,
            );

        if (!mounted) return;

        setState(() {
          _myItems = items;
          _sellerReviews = reviews;
          _sellerUnopenedOrders = sellerUnopenedOrders;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _myItems = [];
          _sellerReviews = [];
          _sellerUnopenedOrders = 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _myItems = [];
        _sellerReviews = [];
        _sellerUnopenedOrders = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFavorites() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    try {
      final favorites = await ProductService().getFavoriteProducts(
        forceRefresh: true,
      );
      final favoriteIds = favorites
          .map((p) => int.tryParse(p['id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();

      if (!mounted) return;

      setState(() {
        for (var i = 0; i < _myItems.length; i++) {
          final id = int.tryParse(_myItems[i]['id']?.toString() ?? '');
          final isFav = id != null && favoriteIds.contains(id);
          _myItems[i]['isFavorite'] = isFav ? 1 : 0;
          _myItems[i]['liked'] = isFav;
        }
      });
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _openSalesOrders() async {
    await Navigator.pushNamed(context, '/sales');
    if (mounted) _loadData();
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final productId = item['id'];
    final isLiked =
        item['isFavorite'] == 1 ||
        item['isFavorite'] == true ||
        item['liked'] == 1 ||
        item['liked'] == true;
    final newValue = !isLiked;

    setState(() {
      final idx = _myItems.indexWhere(
        (p) =>
            (productId != null && p['id'] == productId) ||
            (p['name'] == item['name']),
      );
      if (idx != -1) {
        _myItems[idx] = Map<String, dynamic>.from(_myItems[idx])
          ..['isFavorite'] = newValue ? 1 : 0
          ..['liked'] = newValue;
      }
    });

    if (productId != null) {
      final parsedId = productId is int
          ? productId
          : int.tryParse(productId.toString());
      if (parsedId != null) {
        await ProductService().toggleFavorite(parsedId, newValue);
      }
    }
  }

  Future<void> _confirmDeleteProduct(Map<String, dynamic> item) async {
    final productId = int.tryParse(item['id']?.toString() ?? '');
    final sellerId = int.tryParse(item['seller_id']?.toString() ?? '');
    final currentUserId = UserService.currentUserId;

    if (productId == null || sellerId == null || sellerId != currentUserId) {
      _showSnackBar(
        'Produk ini tidak bisa dihapus dari akun ini',
        isError: true,
      );
      return;
    }

    final productName = _text(item['name'], 'produk ini');
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Hapus Jualan?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Produk "$productName" akan dihapus dari daftar jualan kamu.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Hapus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final removedItem = Map<String, dynamic>.from(item);
    final removedIndex = _myItems.indexWhere(
      (product) => product['id']?.toString() == productId.toString(),
    );

    setState(() {
      _myItems.removeWhere(
        (product) => product['id']?.toString() == productId.toString(),
      );
    });

    try {
      await ProductService().deleteProduct(productId, sellerId: currentUserId);
      if (!mounted) return;
      _showSnackBar('Produk berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (removedIndex >= 0 && removedIndex <= _myItems.length) {
          _myItems.insert(removedIndex, removedItem);
        } else {
          _myItems.add(removedItem);
        }
      });
      _showSnackBar('Gagal menghapus produk: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _text(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Rp 0';

    if (value is num) {
      final raw = value.round().toString();
      final formatted = raw.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
      return 'Rp $formatted';
    }

    final text = value.toString();

    if (text.toLowerCase().startsWith('rp')) {
      return text;
    }

    final onlyNumber = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (onlyNumber.isEmpty) return 'Rp 0';

    final formatted = onlyNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  Widget _buildRatingMeta(Map<String, dynamic> item) {
    final rating = double.tryParse(item['rating']?.toString() ?? '') ?? 0;
    final reviewCount =
        int.tryParse(item['reviewCount']?.toString() ?? '') ?? 0;
    final hasRating = rating > 0 && reviewCount > 0;

    if (!hasRating) {
      return const Text(
        'Belum ada rating',
        style: TextStyle(
          fontSize: 9.5,
          color: AppColors.textHint,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB800)),
        const SizedBox(width: 2),
        Text(
          '${rating.toStringAsFixed(1)} ($reviewCount)',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
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
              ).then((_) => _loadData());
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
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(_buildTabBar()),
            ),
          ];
        },
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMyItemsGrid(_myItems),
                  _buildMyItemsGrid(
                    _myItems.where((item) {
                      return item['isBid'] == 1 || item['isBid'] == true;
                    }).toList(),
                    emptyMessage: 'Belum ada lelang aktif',
                  ),
                  _buildReviews(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(color: Color(0xFFEAF8F6)),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: UserAvatar(
              name: _userName,
              photoPath: UserService.currentUser?['photo_path']?.toString(),
              radius: 37,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _userName,
            style: TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Toko $_userName',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _userBio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: _hasBio ? FontWeight.w500 : FontWeight.w400,
              color: _hasBio ? AppColors.textPrimary : AppColors.textSecondary,
              fontStyle: _hasBio ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _openSalesOrders,
              icon: const Icon(Icons.storefront_outlined, size: 17),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Penjualan Saya',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  if (_sellerUnopenedOrders > 0) ...[
                    const SizedBox(width: 8),
                    _buildUnreadBadge(_sellerUnopenedOrders),
                  ],
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 54,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.4,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textPrimary,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Jualan Saya'),
          Tab(text: 'Lelang Aktif'),
          Tab(text: 'Ulasan'),
        ],
      ),
    );
  }

  Widget _buildMyItemsGrid(
    List<Map<String, dynamic>> items, {
    String emptyMessage = 'Belum ada produk',
  }) {
    if (items.isEmpty) {
      return _buildPlaceholder(emptyMessage);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: item),
              ),
            );
            _refreshFavorites();
          },
          child: _buildProductCard(item),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final isBid = item['isBid'] == 1 || item['isBid'] == true;
    final isLiked =
        item['isFavorite'] == 1 ||
        item['isFavorite'] == true ||
        item['liked'] == 1 ||
        item['liked'] == true;
    final imageUrl = _text(item['imageUrl'] ?? item['image'], '');
    final name = _text(item['name'], 'Nama Produk');
    final badge = isBid ? 'Lelang' : _text(item['badge'], 'Like New');
    final location = _text(item['location'], 'Surakarta');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EEF6)),
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
              AspectRatio(aspectRatio: 1, child: _buildProductImage(imageUrl)),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCardIconButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      onTap: () => _confirmDeleteProduct(item),
                    ),
                    const SizedBox(width: 6),
                    _buildCardIconButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isLiked ? Colors.red : AppColors.textSecondary,
                      onTap: () => _toggleFavorite(item),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isBid
                        ? const Color(0xFFFFB21A)
                        : AppColors.primary.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isBid ? const Color(0xFF5A3500) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              name,
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
                    location,
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
            child: _buildRatingMeta(item),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Text(
              _formatPrice(item['price']),
              style: TextStyle(
                fontSize: 16,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: isBid ? const Color(0xFFB96C00) : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder();
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    return CachedProductImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 420,
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF3F6),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 30,
      ),
    );
  }

  Widget _buildReviews() {
    if (_sellerReviews.isEmpty) {
      return _buildPlaceholder('Belum ada ulasan');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _sellerReviews.length,
      itemBuilder: (context, index) => _buildReviewCard(_sellerReviews[index]),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = int.tryParse(review['rating']?.toString() ?? '') ?? 0;
    final reviewerName = review['reviewer_name']?.toString() ?? 'Pembeli';
    final productName = review['product_name']?.toString() ?? 'Produk';
    final comment = review['comment']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: reviewerName,
                photoPath: review['reviewer_photo_path']?.toString(),
                radius: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star_rounded : Icons.star_border,
                    color: AppColors.ratingStar,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final Widget _tabBar;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
