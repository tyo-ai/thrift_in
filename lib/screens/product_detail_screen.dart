import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/user_avatar.dart';
import '../services/bid_service.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import '../services/review_service.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  int _highestBid = 0;
  List<Map<String, dynamic>> _bids = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _seller;
  double _sellerRating = 0.0;
  int _sellerReviewCount = 0;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  bool get _isBid => widget.product['isBid'] == 1;
  bool get _isOwnProduct {
    final sellerId = int.tryParse(
      widget.product['seller_id']?.toString() ?? '',
    );
    return sellerId != null && sellerId == UserService.currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product['isFavorite'] == 1;
    _loadSellerProfile();
    _loadReviews();
    if (_isBid) {
      _loadBids();
      _startTimer();
    }
  }

  void _startTimer() {
    final endTimeStr = widget.product['end_time'];
    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      _updateTimeLeft(endTime);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateTimeLeft(endTime);
      });
    }
  }

  void _updateTimeLeft(DateTime endTime) {
    final now = DateTime.now();
    if (endTime.isAfter(now)) {
      setState(() {
        _timeLeft = endTime.difference(now);
      });
    } else {
      _timer?.cancel();
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  Future<void> _loadBids() async {
    final highest = await BidService().getHighestBid(widget.product['id']);
    final bids = await BidService().getBidsForItem(widget.product['id']);
    if (mounted) {
      setState(() {
        _highestBid = highest;
        _bids = bids;
      });
    }
  }

  Future<void> _loadReviews() async {
    final productId = int.tryParse(widget.product['id']?.toString() ?? '');
    if (productId == null) return;

    final reviews = await ReviewService().getReviewsForProduct(productId);
    if (mounted) {
      setState(() => _reviews = reviews);
    }
  }

  Future<void> _loadSellerProfile() async {
    final sellerId = int.tryParse(
      widget.product['seller_id']?.toString() ?? '',
    );
    if (sellerId == null) return;

    final results = await Future.wait([
      UserService().getUserById(sellerId),
      ReviewService().getSellerReviewSummary(sellerId),
    ]);

    if (!mounted) return;

    final seller = results[0];
    final summary = results[1] as Map<String, dynamic>;
    setState(() {
      _seller = seller;
      _sellerRating = (summary['average'] as num?)?.toDouble() ?? 0.0;
      _sellerReviewCount = int.tryParse(summary['count'].toString()) ?? 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

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

  void _showBidDialog() {
    if (_isOwnProduct) {
      _showAppSnackBar(
        'Kamu tidak bisa menawar barang milik sendiri',
        isError: true,
      );
      return;
    }

    final TextEditingController bidController = TextEditingController();
    final int minBid = _highestBid > 0
        ? _highestBid + 10000
        : _parsePrice(widget.product['price']) + 10000;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Masukkan Tawaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tawaran saat ini: ${_formatPrice(_highestBid)}'),
            const SizedBox(height: 8),
            Text(
              'Minimal tawaran: ${_formatPrice(minBid)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = bidController.text.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              if (amountStr.isEmpty) return;
              final amount = int.parse(amountStr);

              if (amount < minBid) {
                _showAppSnackBar('Tawaran terlalu rendah', isError: true);
                return;
              }

              if (UserService.currentUserId == null) {
                _showAppSnackBar(
                  'Silakan login terlebih dahulu',
                  isError: true,
                );
                return;
              }

              final navigator = Navigator.of(context);
              await BidService().placeBid(
                productId: widget.product['id'],
                buyerId: UserService.currentUserId!,
                amount: amount,
              );

              if (!mounted) return;
              navigator.pop();
              _loadBids();
              _showAppSnackBar(
                'Tawaran berhasil ditempatkan',
                icon: Icons.gavel_rounded,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bid'),
          ),
        ],
      ),
    );
  }

  String _productText(String key, String fallback) {
    final value = widget.product[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  String get _title => _productText('name', 'Harvard Vintage Varsity');
  String get _category => _productText('category', 'Pakaian');
  String get _condition => _productText('condition', 'Pernah Dipakai');
  String get _badge => _productText('badge', _isBid ? 'Langka' : 'Baru');
  String get _storeName => _productText('storeName', 'Vintage Heritage');
  String get _imageUrl => _productText(
    'imageUrl',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
  );

  void _showAppSnackBar(
    String message, {
    bool isError = false,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    if (UserService.currentUserId == null) {
      _showAppSnackBar('Silakan login terlebih dahulu', isError: true);
      return;
    }
    if (_isOwnProduct) {
      _showAppSnackBar(
        'Kamu tidak bisa menambahkan barang milik sendiri',
        isError: true,
      );
      return;
    }
    if (_isBid) {
      _showAppSnackBar(
        'Produk lelang tidak bisa masuk keranjang',
        isError: true,
      );
      return;
    }

    final productId = int.tryParse(item['id']?.toString() ?? '');
    if (productId == null) {
      _showAppSnackBar('Produk tidak valid', isError: true);
      return;
    }

    try {
      await CartService().addToCart(productId);
      _showAppSnackBar('Produk masuk keranjang');
    } catch (e) {
      _showAppSnackBar('Gagal menambahkan ke keranjang: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildHeroImage(), _buildProductInfo(item)],
                  ),
                ),
                _buildFloatingHeader(),
              ],
            ),
          ),
          _buildBottomActionBar(item),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Map<String, dynamic> item) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    if (_isOwnProduct) {
                      _showAppSnackBar(
                        'Kamu tidak bisa chat barang milik sendiri',
                        isError: true,
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(product: item),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 52,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onPressed: () => _addToCart(item),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isBid && _timeLeft.inSeconds > 0)
                      ? _showBidDialog
                      : () {
                          if (_isOwnProduct) {
                            _showAppSnackBar(
                              'Kamu tidak bisa membeli barang milik sendiri',
                              isError: true,
                            );
                            return;
                          }

                          final finalPrice = _highestBid > 0
                              ? _highestBid
                              : _parsePrice(item['price']);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                product: item,
                                finalPrice: finalPrice,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isBid
                        ? (_timeLeft.inSeconds > 0
                              ? 'Bid Sekarang'
                              : 'Lelang Berakhir')
                        : 'Beli Sekarang',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _imageUrls {
    final images = widget.product['images'];
    if (images is List && images.isNotEmpty) {
      return images.map((e) => e.toString()).where((url) => url.trim().isNotEmpty).toList();
    }
    return [_imageUrl];
  }

  Widget _buildHeroImage() {
    final images = _imageUrls;
    final height = MediaQuery.sizeOf(context).height * 0.44;
    final clampedHeight = height.clamp(360.0, 430.0);

    if (images.length <= 1) {
      return SizedBox(
        height: clampedHeight,
        width: double.infinity,
        child: CachedProductImage(
          imageUrl: images.isNotEmpty ? images.first : _imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          memCacheWidth: 900,
        ),
      );
    }

    return SizedBox(
      height: clampedHeight,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImagePage = index);
            },
            itemBuilder: (context, index) {
              return CachedProductImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheWidth: 900,
              );
            },
          ),
          // Page indicator dots
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == _currentImagePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
          // Page counter badge
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_currentImagePage + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
              _buildCircleButton(
                icon: _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: _isFavorite ? AppColors.error : AppColors.primary,
                onPressed: () async {
                  final newFav = !_isFavorite;
                  final productId = widget.product['id'];
                  setState(() => _isFavorite = newFav);
                  if (productId != null) {
                    await ProductService().toggleFavorite(productId, newFav);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = AppColors.primary,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 26),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildTag(_category),
              _buildTag(_condition),
              _buildTag(_badge, isHighlighted: true),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildProductRatingMeta(item),
          const SizedBox(height: 14),
          _buildPriceSection(item),
          const SizedBox(height: 16),
          _buildFullWidthSellerCard(),
          const SizedBox(height: 24),
          const Text(
            'Deskripsi Produk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _productText(
              'description',
              'Tidak ada deskripsi untuk produk ini.',
            ),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (_isBid && _bids.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Riwayat Tawaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._bids
                .take(3)
                .map(
                  (bid) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bid['buyer_name']?.toString() ?? 'Pembeli',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatPrice(bid['amount']),
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Ulasan Pembeli',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._reviews.take(3).map(_buildReviewTile),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final rating = int.tryParse(review['rating']?.toString() ?? '') ?? 0;
    final reviewerName = review['reviewer_name']?.toString() ?? 'Pembeli';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: reviewerName,
                photoPath: review['reviewer_photo_path']?.toString(),
                radius: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reviewerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star_rounded : Icons.star_border,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if ((review['comment']?.toString().trim() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review['comment'].toString(),
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

  Widget _buildProductRatingMeta(Map<String, dynamic> item) {
    final rating = double.tryParse(item['rating']?.toString() ?? '') ?? 0;
    final reviewCount =
        int.tryParse(item['reviewCount']?.toString() ?? '') ?? 0;
    final hasRating = rating > 0 && reviewCount > 0;

    if (!hasRating) {
      return const Text(
        'Belum ada rating produk',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textHint,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($reviewCount ulasan)',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(Map<String, dynamic> item) {
    final price = _isBid
        ? (_highestBid > 0 ? _highestBid : _parsePrice(item['price']))
        : _parsePrice(item['price']);
    final timeText = _timeLeft.inSeconds > 0
        ? _formatDuration(_timeLeft)
        : _isBid
        ? '167:43:11'
        : '';

    if (!_isBid) {
      return _buildMetric(label: 'Harga', value: _formatPrice(price));
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetric(
            label: 'Bid Saat Ini',
            value: _formatPrice(price),
          ),
        ),
        Container(width: 1, height: 66, color: AppColors.border),
        const SizedBox(width: 28),
        Expanded(
          child: _buildMetric(
            label: 'Sisa Waktu',
            value: timeText,
            valueColor: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    Color valueColor = AppColors.primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCard() {
    final sellerName = _seller?['name']?.toString().trim();
    final displayName = sellerName == null || sellerName.isEmpty
        ? _storeName
        : sellerName;
    final sellerPhotoPath = _seller?['photo_path']?.toString();
    final reviewText = _sellerReviewCount == 0
        ? 'Belum ada ulasan'
        : '${_sellerRating.toStringAsFixed(1)} ($_sellerReviewCount ulasan)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          UserAvatar(name: displayName, photoPath: sellerPhotoPath, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      reviewText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthSellerCard() {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Transform.translate(
      offset: const Offset(-32, 0),
      child: SizedBox(width: screenWidth, child: _buildSellerCard()),
    );
  }

  Widget _buildTag(String text, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isHighlighted
              ? const Color(0xFFE65100)
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}
