import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar_drawer.dart';
import '../services/product_service.dart';
import 'saved_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService().getProducts();

      if (!mounted) return;

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
      _filterProducts();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allProducts = [];
        _products = [];
        _isLoading = false;
      });
    }
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
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 22,
            ),
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
              ).then((_) => _loadProducts());
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
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

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

              _buildCategoryTabs(),

              const SizedBox(height: 16),

              _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : _buildProductGrid(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
          Icon(
            Icons.circle,
            size: 7,
            color: Color(0xFFFF5A3D),
          ),
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
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(20, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBiddingList() {
    final liveItems = [
      {
        'name': 'Vintage Y3 Originals Multi-Color Jacket',
        'tag': 'Rare',
        'price': 'Rp 850.000',
        'time': '04:12:34',
        'image':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
      },
      {
        'name': 'Heritage Leather Brown Bag',
        'tag': 'Rare',
        'price': 'Rp 1.200.000',
        'time': '01:40:28',
        'image':
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
      },
    ];

    return SizedBox(
      height: 265,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: liveItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = liveItems[index];

          return _buildLiveAuctionCard(
            imageUrl: item['image']!,
            name: item['name']!,
            tag: item['tag']!,
            price: item['price']!,
            time: item['time']!,
          );
        },
      ),
    );
  }

  Widget _buildLiveAuctionCard({
    required String imageUrl,
    required String name,
    required String tag,
    required String price,
    required String time,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: _buildImage(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                ),
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
                    color: const Color(0xFFE6F7F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              'Bid Saat Ini:',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    price,
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
                    onPressed: () {},
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
                      'Bid Sekarang',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          mainAxisSpacing: 12,
          childAspectRatio: 0.67,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              ).then((_) => _loadProducts());
            },
            child: _buildProductCard(product, index),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final isFavorite =
        product['isFavorite'] == 1 || product['isFavorite'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
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
              _buildImage(
                _text(product['imageUrl'], ''),
                height: 120,
                width: double.infinity,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final newValue = !isFavorite;

                    final productId = product['id'];

                    setState(() {
                      _products[index] = Map<String, dynamic>.from(product)
                        ..['isFavorite'] = newValue ? 1 : 0;
                      
                      if (productId != null) {
                        final rawIdx = _allProducts.indexWhere((p) => p['id'] == productId);
                        if (rawIdx != -1) {
                          _allProducts[rawIdx] = Map<String, dynamic>.from(_allProducts[rawIdx])
                            ..['isFavorite'] = newValue ? 1 : 0;
                        }
                      }
                    });

                    if (productId != null) {
                      await ProductService().toggleFavorite(
                        productId,
                        newValue,
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 7,
                bottom: 7,
                child: Row(
                  children: [
                    _buildMiniTag('Refurb'),
                    const SizedBox(width: 4),
                    _buildMiniTag('COD', orange: true),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Color(0xFFFFB800),
                ),
                const SizedBox(width: 3),
                Text(
                  _text(product['rating'], '4.8'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${_text(product['reviewCount'], '15')})',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 4, 9, 0),
            child: Text(
              _text(product['name'], 'Nama Produk'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 4, 9, 0),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${_text(product['storeName'], 'Toko')} • ${_text(product['location'], 'Surakarta')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 0, 9, 10),
            child: Text(
              _formatPrice(product['price']),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String text, {bool orange = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: orange ? const Color(0xFFFFC247) : AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: orange ? const Color(0xFF4B3200) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildImage(
    String imageUrl, {
    required double height,
    required double width,
  }) {
    if (imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder(height: height, width: width);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return _buildImagePlaceholder(height: height, width: width);
        },
      );
    }

    return Image.asset(
      imageUrl,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) {
        return _buildImagePlaceholder(height: height, width: width);
      },
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