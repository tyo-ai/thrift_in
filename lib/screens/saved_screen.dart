import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/skeleton_loaders.dart';
import 'product_detail_screen.dart';
import 'notifications_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites({bool forceRefresh = false, bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final favorites = await ProductService().getFavoriteProducts(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _favoriteProducts = favorites;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int id) async {
    await ProductService().toggleFavorite(id, false);
    if (!mounted) return;
    await _loadFavorites(forceRefresh: true);
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
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bidItems = _favoriteProducts.where((p) => p['isBid'] == 1).toList();
    final fixedItems = _favoriteProducts.where((p) => p['isBid'] == 0).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Tersimpan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Lelang'),
            Tab(text: 'Harga Tetap'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(_favoriteProducts),
          _buildGrid(bidItems),
          _buildGrid(fixedItems),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    if (_isLoading) {
      return SkeletonLoaders.productGrid(
        padding: const EdgeInsets.all(16),
        childAspectRatio: 0.66,
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: false,
      );
    }

    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada item tersimpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tekan ikon ❤️ pada produk di Beranda\nuntuk menyimpannya di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadFavorites(forceRefresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.66,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isLelang = item['isBid'] == 1;
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: item),
                ),
              );
              _loadFavorites(forceRefresh: true, silent: true);
            },
            child: Container(
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
                  // Gambar produk
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                        child: _buildSavedImage(item['imageUrl'] ?? ''),
                      ),
                      // Badge
                      if (isLelang ||
                          (item['badge'] != null &&
                              (item['badge'] as String).isNotEmpty))
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isLelang
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLelang ? 'Lelang' : (item['badge'] ?? ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      // Tombol hapus favorit
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            final id = item['id'];
                            if (id != null) {
                              _removeFavorite(id as int);
                            }
                          },
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.red,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Detail produk
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
                    child: _buildRatingMeta(item),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 0),
                    child: Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${_text(item['storeName'] ?? item['store'], 'Toko')} · ${_text(item['location'], 'Surakarta')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
                    child: Text(
                      _formatPrice(item['price']),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedImage(dynamic value) {
    final imageUrl = value?.toString().trim() ?? '';
    if (imageUrl.isEmpty) {
      return _buildSavedImagePlaceholder();
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        height: 125,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildSavedImagePlaceholder();
        },
      );
    }

    return CachedProductImage(
      imageUrl: imageUrl,
      height: 125,
      width: double.infinity,
      fit: BoxFit.contain,
      memCacheWidth: 420,
    );
  }

  Widget _buildSavedImagePlaceholder() {
    return Container(
      height: 125,
      width: double.infinity,
      color: const Color(0xFFF4F7FB),
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFFB0BEC5),
        size: 30,
      ),
    );
  }
}
