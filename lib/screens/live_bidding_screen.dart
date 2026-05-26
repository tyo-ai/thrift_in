import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import 'product_detail_screen.dart';
import '../services/db_helper.dart';
import '../services/bid_service.dart';

class LiveBiddingScreen extends StatefulWidget {
  const LiveBiddingScreen({super.key});

  @override
  State<LiveBiddingScreen> createState() => _LiveBiddingScreenState();
}

class _LiveBiddingScreenState extends State<LiveBiddingScreen> {
  List<Map<String, dynamic>> _biddingItems = [];

  @override
  void initState() {
    super.initState();
    _loadBiddingItems();
  }

  Future<void> _loadBiddingItems() async {
    try {
      final db = await DbHelper().database;
      final results = await db.query('products', where: 'isBid = ?', whereArgs: [1]);
      setState(() {
        _biddingItems = results;
      });
    } catch (e) {
      // ignore
    }
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
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
      body: SingleChildScrollView(
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
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE NOW',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lelang Sedang\nBerlangsung',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2),
                  ),
                ],
              ),
            ),

            // Grid View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemCount: _biddingItems.length,
                itemBuilder: (context, index) {
                  final item = _biddingItems[index];
                  return LiveBiddingGridCard(item: item);
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
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
    final bool isNetwork = imageUrl.startsWith('http');
    final String currentPrice = _highestBid > 0
        ? _formatPrice(_highestBid)
        : _formatPrice(item['price']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailScreen(product: widget.item)), 
        ).then((_) => _loadBids());
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: isNetwork
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Image.file(File(imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['storeName'],
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tawaran Tertinggi', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentPrice,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$_bidsCount Bids', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                      label: const Text('Bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
