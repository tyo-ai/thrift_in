import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'product_detail_screen.dart';
import '../services/bid_service.dart';
import '../services/product_service.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/skeleton_loaders.dart';

class LiveBiddingScreen extends StatefulWidget {
  const LiveBiddingScreen({super.key});

  @override
  State<LiveBiddingScreen> createState() => _LiveBiddingScreenState();
}

class _LiveBiddingScreenState extends State<LiveBiddingScreen> {
  static const int _pageSize = ProductService.defaultPageSize;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _biddingItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadBiddingItems();
  }

  Future<void> _loadBiddingItems({bool forceRefresh = false}) async {
    try {
      final results = await ProductService().getLiveProducts(
        limit: _pageSize,
        offset: 0,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _biddingItems = results;
        _offset = results.length;
        _hasMore = results.length == _pageSize;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreBiddingItems() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final results = await ProductService().getLiveProducts(
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _biddingItems.addAll(results);
        _offset += results.length;
        _hasMore = results.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _handleScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      _loadMoreBiddingItems();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thriftin',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadBiddingItems(forceRefresh: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE NOW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lelang Sedang\nBerlangsung',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Grid View
              if (_isLoading)
                SkeletonLoaders.productGrid(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  childAspectRatio: 0.65,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                    itemCount: _biddingItems.length,
                    itemBuilder: (context, index) {
                      final item = _biddingItems[index];
                      return LiveBiddingGridCard(item: item);
                    },
                  ),
                ),
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class LiveBiddingGridCard extends StatefulWidget {
  final Map<String, dynamic> item;

  const LiveBiddingGridCard({super.key, required this.item});

  @override
  State<LiveBiddingGridCard> createState() => _LiveBiddingGridCardState();
}

class _LiveBiddingGridCardState extends State<LiveBiddingGridCard> {
  int _highestBid = 0;
  int _bidsCount = 0;

  int _parsePrice(dynamic value) {
    final raw = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(raw) ?? 0;
  }

  String _formatPrice(dynamic value) {
    final price = value is int ? value : _parsePrice(value);
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    final highest = await BidService().getHighestBid(widget.item['id']);
    final bids = await BidService().getBidsForItem(widget.item['id']);
    if (mounted) {
      setState(() {
        _highestBid = highest;
        _bidsCount = bids.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imageUrl = item['imageUrl'] as String;
    final String currentPrice = _highestBid > 0
        ? _formatPrice(_highestBid)
        : _formatPrice(item['price']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: widget.item),
          ),
        ).then((_) => _loadBids());
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: CachedProductImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 420,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['storeName'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tawaran Tertinggi',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$_bidsCount Bids',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Nanti ke BidDetailScreen
                      },
                      icon: const Icon(Icons.gavel_rounded, size: 14),
                      label: const Text(
                        'Bid',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
}
