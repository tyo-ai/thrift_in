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

  void _showBidDialog() {
    final TextEditingController bidController = TextEditingController();
    final int minBid = _highestBid > 0 ? _highestBid + 10000 : int.parse(widget.product['price'].replaceAll(RegExp(r'[^0-9]'), '')) + 10000;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Masukkan Tawaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tawaran saat ini: Rp $_highestBid'),
            const SizedBox(height: 8),
            Text('Minimal tawaran: Rp $minBid', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              final amountStr = bidController.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (amountStr.isEmpty) return;
              final amount = int.parse(amountStr);
              
              if (amount < minBid) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tawaran terlalu rendah')));
                return;
              }
              
              if (UserService.currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
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
              messenger.showSnackBar(const SnackBar(content: Text('Tawaran berhasil ditempatkan')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Bid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    final imageUrl = item['imageUrl'] as String;
    final isNetwork = imageUrl.startsWith('http');
    
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      isNetwork
                          ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Image.file(File(imageUrl), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTag(item['category'] ?? 'Kategori'),
                          const SizedBox(width: 8),
                          _buildTag(item['condition'] ?? 'Kondisi'),
                          if (item['badge'] != null) ...[
                            const SizedBox(width: 8),
                            _buildTag(item['badge'], isHighlighted: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        item['name'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isBid ? 'Bid Saat Ini' : 'Harga',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isBid 
                                    ? (_highestBid > 0 ? 'Rp $_highestBid' : item['price'])
                                    : item['price'].toString().startsWith('Rp') ? item['price'] : 'Rp ${item['price']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          if (_isBid) ...[
                            Container(width: 1, height: 40, color: AppColors.border),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sisa Waktu', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeLeft.inSeconds > 0 ? _formatDuration(_timeLeft) : 'Berakhir',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['storeName'] ?? 'Toko Penjual', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  const Row(
                                    children: [
                                      Icon(Icons.star, color: Color(0xFFF59E0B), size: 12),
                                      SizedBox(width: 4),
                                      Text('4.9 (124 ulasan)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (_isBid && _bids.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Riwayat Tawaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        ..._bids.take(3).map((bid) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bid['buyer_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Rp ${bid['amount']}', style: const TextStyle(color: AppColors.primary)),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom AppBar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9)),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? AppColors.error : AppColors.primary),
                          onPressed: () async {
                            final newFav = !_isFavorite;
                            final productId = widget.product['id'];
                            setState(() => _isFavorite = newFav);
                            if (productId != null) {
                              await ProductService().toggleFavorite(productId, newFav);
                            }
                          },
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 16)]),
              child: Row(
                children: [
                  Container(
                    height: 52, width: 52,
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                    child: IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary), onPressed: () {}),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isBid && _timeLeft.inSeconds > 0) ? _showBidDialog : () {
                          int finalPrice = _highestBid > 0 ? _highestBid : int.parse(item['price'].toString().replaceAll(RegExp(r'[^0-9]'), ''));
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CheckoutScreen(product: item, finalPrice: finalPrice)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _isBid 
                            ? (_timeLeft.inSeconds > 0 ? 'Bid Sekarang' : 'Lelang Berakhir')
                            : 'Beli Sekarang',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFF3E0) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHighlighted ? const Color(0xFFE65100) : AppColors.textSecondary,
        ),
      ),
    );
  }
}
