import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/product_detail_screen.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/skeleton_loaders.dart';
import 'saved_screen.dart';
import 'notifications_screen.dart';
import 'cart_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const int _pageSize = ProductService.defaultPageSize;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _lastLiveQuery = '';

  int _selectedFilter = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  final List<String> _filterChips = [
    'Semua',
    '90s Style',
    'Denim',
    'Windbreaker',
    'Vintage',
    'Jaket',
  ];

  List<Map<String, dynamic>> _allRawProducts = [];
  List<Map<String, dynamic>> _results = [];

  // Filter & Sort Settings
  String _sortBy = 'Terbaru'; // 'Terbaru', 'Harga Terendah', 'Harga Tertinggi'
  String _saleType = 'Semua'; // 'Semua', 'Tersedia', 'Lelang'
  double? _minPrice;
  double? _maxPrice;
  String _condition =
      'Semua'; // 'Semua', 'Baru', 'Sangat Bagus', 'Pernah Dipakai'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleLiveSearch);
    _scrollController.addListener(_handleScroll);
    _performSearch('');
  }

  Future<void> _performSearch(String query, {bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      final results = await ProductService().searchProducts(
        query,
        limit: _pageSize,
        offset: 0,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _allRawProducts = results;
        _offset = results.length;
        _hasMore = results.length == _pageSize;
        _isLoading = false;
      });
      _applyFilters();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allRawProducts = [];
        _offset = 0;
        _hasMore = false;
        _isLoading = false;
      });
      _applyFilters();
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
        for (var i = 0; i < _allRawProducts.length; i++) {
          final id = int.tryParse(_allRawProducts[i]['id']?.toString() ?? '');
          _allRawProducts[i]['isFavorite'] = (id != null && favoriteIds.contains(id)) ? 1 : 0;
        }
        _applyFilters();
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

  Future<void> _loadMoreResults() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final results = await ProductService().searchProducts(
        _searchController.text,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _allRawProducts.addAll(results);
        _offset += results.length;
        _hasMore = results.length == _pageSize;
        _isLoadingMore = false;
      });
      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _handleScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      _loadMoreResults();
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List.from(_allRawProducts);

    // 1. Filter by category chip (_selectedFilter)
    if (_selectedFilter > 0) {
      final chip = _filterChips[_selectedFilter].toLowerCase();
      temp = temp.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final cat = (item['category'] ?? '').toString().toLowerCase();

        if (chip == '90s style') {
          return name.contains('90s') ||
              name.contains('style') ||
              name.contains('retro');
        } else if (chip == 'denim') {
          return name.contains('denim') ||
              name.contains('levis') ||
              name.contains('levi’s') ||
              name.contains('trucker');
        } else if (chip == 'windbreaker') {
          return name.contains('windbreaker');
        } else if (chip == 'vintage') {
          return name.contains('vintage') ||
              name.contains('retro') ||
              name.contains('varsity');
        } else if (chip == 'jaket') {
          return name.contains('jaket') ||
              name.contains('jacket') ||
              name.contains('varsity') ||
              name.contains('bomber') ||
              name.contains('biker') ||
              name.contains('trench');
        }
        return name.contains(chip) || cat.contains(chip);
      }).toList();
    }

    // 2. Filter by sale type (_saleType)
    if (_saleType != 'Semua') {
      final targetBid = _saleType == 'Lelang';
      temp = temp.where((item) => _isBidItem(item) == targetBid).toList();
    }

    // 3. Filter by condition (_condition)
    if (_condition != 'Semua') {
      temp = temp.where((item) {
        final cond = (item['condition'] ?? '').toString().toLowerCase();
        final badge = (item['badge'] ?? '').toString().toLowerCase();
        final target = _condition.toLowerCase();
        return cond == target || badge == target;
      }).toList();
    }

    // 4. Filter by price range (_minPrice, _maxPrice)
    if (_minPrice != null) {
      temp = temp
          .where((item) => _parsePrice(item['price']) >= _minPrice!)
          .toList();
    }
    if (_maxPrice != null) {
      temp = temp
          .where((item) => _parsePrice(item['price']) <= _maxPrice!)
          .toList();
    }

    // 5. Sort (_sortBy)
    if (_sortBy == 'Harga Terendah') {
      temp.sort(
        (a, b) => _parsePrice(a['price']).compareTo(_parsePrice(b['price'])),
      );
    } else if (_sortBy == 'Harga Tertinggi') {
      temp.sort(
        (a, b) => _parsePrice(b['price']).compareTo(_parsePrice(a['price'])),
      );
    } else {
      // Default: Terbaru (using id DESC)
      temp.sort((a, b) {
        final idA = a['id'] ?? 0;
        final idB = b['id'] ?? 0;
        return idB.compareTo(idA);
      });
    }

    setState(() {
      _results = temp;
    });
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final clean = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada produk ditemukan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ubah kata kunci pencarian atau filter Anda.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final TextEditingController minController = TextEditingController(
              text: _minPrice != null ? _minPrice!.round().toString() : '',
            );
            final TextEditingController maxController = TextEditingController(
              text: _maxPrice != null ? _maxPrice!.round().toString() : '',
            );

            Widget buildSectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }

            Widget buildChipsRow({
              required List<String> options,
              required String selectedValue,
              required ValueChanged<String> onSelected,
            }) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final isSelected = opt == selectedValue;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        onSelected(opt);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE0E7EF),
                        ),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Urutkan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              minController.clear();
                              maxController.clear();
                            });
                            Navigator.pop(context);
                            setState(() {
                              _sortBy = 'Terbaru';
                              _saleType = 'Semua';
                              _minPrice = null;
                              _maxPrice = null;
                              _condition = 'Semua';
                            });
                            _applyFilters();
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            'Reset Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFEFF3F8)),

                    buildSectionTitle('Urutkan Berdasarkan'),
                    buildChipsRow(
                      options: const [
                        'Terbaru',
                        'Harga Terendah',
                        'Harga Tertinggi',
                      ],
                      selectedValue: _sortBy,
                      onSelected: (val) => _sortBy = val,
                    ),

                    buildSectionTitle('Tipe Penjualan'),
                    buildChipsRow(
                      options: const ['Semua', 'Tersedia', 'Lelang'],
                      selectedValue: _saleType,
                      onSelected: (val) => _saleType = val,
                    ),

                    buildSectionTitle('Kondisi Barang'),
                    buildChipsRow(
                      options: const [
                        'Semua',
                        'Baru',
                        'Sangat Bagus',
                        'Pernah Dipakai',
                      ],
                      selectedValue: _condition,
                      onSelected: (val) => _condition = val,
                    ),

                    buildSectionTitle('Rentang Harga (Rp)'),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E9F0),
                              ),
                            ),
                            child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Min',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '—',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E9F0),
                              ),
                            ),
                            child: TextField(
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Max',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final minVal = double.tryParse(
                            minController.text.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            ),
                          );
                          final maxVal = double.tryParse(
                            maxController.text.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            ),
                          );
                          Navigator.pop(context);
                          setState(() {
                            _minPrice = minVal;
                            _maxPrice = maxVal;
                          });
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terapkan Filter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleLiveSearch() {
    final query = _searchController.text;
    if (query == _lastLiveQuery) return;
    _lastLiveQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      _performSearch(query);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_handleLiveSearch);
    _searchController.dispose();
    super.dispose();
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

    if (onlyNumber.isEmpty) return text;

    final formatted = onlyNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  String _text(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  Widget _buildRatingMeta(Map<String, dynamic> item, {double fontSize = 9.5}) {
    final rating = double.tryParse(item['rating']?.toString() ?? '') ?? 0;
    final reviewCount =
        int.tryParse(item['reviewCount']?.toString() ?? '') ?? 0;
    final hasRating = rating > 0 && reviewCount > 0;

    if (!hasRating) {
      return Text(
        'Belum ada rating',
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.textHint,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: fontSize + 2.5,
          color: const Color(0xFFFFB800),
        ),
        const SizedBox(width: 2),
        Text(
          '${rating.toStringAsFixed(1)} ($reviewCount)',
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  bool _isBidItem(Map<String, dynamic> item) {
    return item['isBid'] == 1 ||
        item['isBid'] == true ||
        _text(item['badge']).toLowerCase().contains('lelang');
  }

  String _getTimeLeft(Map<String, dynamic> item) {
    if (item['time'] != null) {
      return item['time'].toString();
    }
    final endTimeStr = item['end_time'];
    if (endTimeStr != null) {
      try {
        final endTime = DateTime.parse(endTimeStr);
        final diff = endTime.difference(DateTime.now());
        if (diff.isNegative) {
          return 'Berakhir';
        }
        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
        return '$hours:$minutes:$seconds';
      } catch (_) {
        return '02:14:55';
      }
    }
    return '02:14:55';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
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
      body: Column(
        children: [
          _buildSearchArea(),
          _buildFilterChips(),
          _buildResultHeader(),
          Expanded(
            child: _isLoading
                ? SkeletonLoaders.productGrid(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                    physics: const AlwaysScrollableScrollPhysics(),
                    shrinkWrap: false,
                  )
                : _results.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE1EAF2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 13),
                  Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          _performSearch('');
                        }
                      },
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        itemCount: _filterChips.length,
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
              _searchController.clear();
              _performSearch('');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE0E7EF),
                ),
              ),
              child: Center(
                child: Text(
                  _filterChips[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultHeader() {
    final queryText = _searchController.text.trim().isEmpty
        ? 'Semua'
        : _searchController.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Menampilkan ${_results.length} hasil untuk ',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '"$queryText"',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  _sortBy,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      itemCount: _results.length + (_hasMore || _isLoadingMore ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return _buildLoadMoreIndicator();
        }

        final item = _results[index];

        return GestureDetector(
          onTap: () => _navigateToProductDetail(item),
          child: _buildProductCard(item),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return GridTile(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoadingMore
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
            const SizedBox(height: 6),
            Text(
              _isLoadingMore ? 'Memuat...' : 'Scroll untuk lainnya',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    if (MediaQuery.maybeOf(context) != null) {
      return _buildHomeStyleProductCard(item);
    }

    final isBid = _isBidItem(item);
    final badgeText = isBid ? '\$ LELANG' : _text(item['badge'], 'TERSEDIA');
    final imageUrl = _text(item['imageUrl'] ?? item['image'], '');
    final name = _text(item['name'], 'Nama Produk');
    final location = _text(
      item['location'] ?? item['storeName'] ?? item['store'],
      'Surakarta',
    );
    final isFavorite = item['isFavorite'] == 1 || item['isFavorite'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5EDF5)),
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
              _buildSearchCardImage(imageUrl),
              Positioned(
                top: 7,
                left: 7,
                child: _buildBadge(badgeText, isBid: isBid),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final productId = item['id'];
                    if (productId != null) {
                      final newFav = !isFavorite;
                      await ProductService().toggleFavorite(productId, newFav);

                      setState(() {
                        item['isFavorite'] = newFav ? 1 : 0;
                        final rawIdx = _allRawProducts.indexWhere(
                          (p) => p['id'] == productId,
                        );
                        if (rawIdx != -1) {
                          _allRawProducts[rawIdx] = Map<String, dynamic>.from(
                            _allRawProducts[rawIdx],
                          )..['isFavorite'] = newFav ? 1 : 0;
                        }
                      });
                    }
                  },
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
              if (isBid)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 20,
                    alignment: Alignment.center,
                    color: Colors.black.withValues(alpha: 0.48),
                    child: Text(
                      'Berakhir dlm ${_getTimeLeft(item)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
            child: _buildRatingMeta(item),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 1, 6, 0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 1, 6, 0),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textSecondary,
                  size: 13,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
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
              style: TextStyle(
                fontSize: 16,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: isBid ? const Color(0xFFB96C00) : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeStyleProductCard(Map<String, dynamic> item) {
    final isBid = _isBidItem(item);
    final badgeText = isBid ? 'Lelang' : _text(item['badge'], 'Tersedia');
    final imageUrl = _text(item['imageUrl'] ?? item['image'], '');
    final name = _text(item['name'], 'Nama Produk');
    final location = _text(item['location'], 'Lokasi belum diisi');
    final isFavorite = item['isFavorite'] == 1 || item['isFavorite'] == true;

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
                child: _buildImage(imageUrl, width: double.infinity),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final productId = item['id'];
                    if (productId != null) {
                      final newFav = !isFavorite;
                      await ProductService().toggleFavorite(productId, newFav);

                      setState(() {
                        item['isFavorite'] = newFav ? 1 : 0;
                        final rawIdx = _allRawProducts.indexWhere(
                          (p) => p['id'] == productId,
                        );
                        if (rawIdx != -1) {
                          _allRawProducts[rawIdx] = Map<String, dynamic>.from(
                            _allRawProducts[rawIdx],
                          )..['isFavorite'] = newFav ? 1 : 0;
                        }
                      });
                    }
                  },
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
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
                child: _buildBadge(badgeText, isBid: isBid),
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
            child: _buildRatingMeta(item, fontSize: 10.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Text(
              _formatPrice(item['price']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildSearchCardImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return AspectRatio(aspectRatio: 1, child: _buildImagePlaceholder());
    }

    if (imageUrl.startsWith('assets/')) {
      return AspectRatio(
        aspectRatio: 1,
        child: Image.asset(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildImagePlaceholder(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: CachedProductImage(
        imageUrl: imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheWidth: 420,
      ),
    );
  }

  Widget _buildBadge(String text, {required bool isBid}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isBid ? const Color(0xFFFFB21A) : AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          color: isBid ? const Color(0xFF5A3500) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl, {double? height, double width = double.infinity}) {
    final h = height ?? 142;
    if (imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder(height: h, width: width);
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _buildImagePlaceholder(height: h, width: width);
        },
      );
    }

    return CachedProductImage(
      imageUrl: imageUrl,
      width: width,
      height: h,
      fit: BoxFit.cover,
      memCacheWidth: 420,
    );
  }

  Widget _buildImagePlaceholder({double height = 142, double width = double.infinity}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEFF3F6),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 30,
      ),
    );
  }
}
