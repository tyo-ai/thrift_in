import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/product_detail_screen.dart';
import '../services/product_service.dart';
import 'saved_screen.dart';
import 'notifications_screen.dart';
import 'my_orders_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedFilter = 0;
  bool _isLoading = true;

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
    _performSearch('');
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final results = await ProductService().searchProducts(query);

      if (!mounted) return;

      setState(() {
        _allRawProducts = results;
        _isLoading = false;
      });
      _applyFilters();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allRawProducts = [];
        _isLoading = false;
      });
      _applyFilters();
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

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 56,
        titleSpacing: 16,
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
            icon: const Icon(Icons.favorite_border_rounded),
            color: AppColors.textPrimary,
            iconSize: 21,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedScreen()),
              ).then((_) => _performSearch(_searchController.text));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.textPrimary,
            iconSize: 21,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            color: AppColors.textPrimary,
            iconSize: 21,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
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
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
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
                        hintText: 'Jaket Vintage',
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      itemCount: _results.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 0.53,
      ),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return _buildLoadMoreIndicator();
        }

        final item = _results[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: item),
              ),
            ).then((_) => _performSearch(_searchController.text));
          },
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
            Icon(Icons.refresh_rounded, size: 22, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              'Memuat lebih banyak...',
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
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 9,
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
              _buildImage(imageUrl),
              Positioned(
                top: 7,
                left: 7,
                child: _buildBadge(badgeText, isBid: isBid),
              ),
              Positioned(
                top: 7,
                right: 7,
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
                      color: Colors.white.withValues(alpha: 0.82),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? AppColors.error : Colors.white,
                      shadows: isFavorite
                          ? null
                          : [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 4,
                              ),
                            ],
                      size: 18,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatPrice(item['price']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: isBid
                          ? const Color(0xFFB96C00)
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder();
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 138,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _buildImagePlaceholder();
        },
      );
    }

    return Image.asset(
      imageUrl,
      width: double.infinity,
      height: 138,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 138,
      color: const Color(0xFFEFF3F6),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 34,
      ),
    );
  }
}
