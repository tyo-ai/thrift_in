import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../theme/app_colors.dart';
import '../services/bid_service.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import 'checkout_screen.dart';

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
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  bool get _isBid => widget.product['isBid'] == 1;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product['isFavorite'] == 1;
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

  @override
  void dispose() {
    _timer?.cancel();
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tawaran terlalu rendah')),
                );
                return;
              }

              if (UserService.currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Silakan login terlebih dahulu'),
                  ),
                );
                return;
              }

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              await BidService().placeBid(
                productId: widget.product['id'],
                buyerId: UserService.currentUserId!,
                amount: amount,
              );

              if (!mounted) return;
              navigator.pop();
              _loadBids();
              messenger.showSnackBar(
                const SnackBar(content: Text('Tawaran berhasil ditempatkan')),
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
                  onPressed: () {},
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

  Widget _buildHeroImage() {
    final isNetwork = _imageUrl.startsWith('http');
    final height = MediaQuery.sizeOf(context).height * 0.44;

    return SizedBox(
      height: height.clamp(360.0, 430.0),
      width: double.infinity,
      child: isNetwork
          ? Image.network(
              _imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => _buildImagePlaceholder(),
            )
          : Image.file(
              File(_imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => _buildImagePlaceholder(),
            ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFE8EEF4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.grey400,
        size: 64,
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
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
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
            _productText('description', 'Tidak ada deskripsi untuk produk ini.'),
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
        ],
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _storeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFF59E0B), size: 13),
                    SizedBox(width: 4),
                    Text(
                      '4.9 (124 ulasan)',
                      style: TextStyle(
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
