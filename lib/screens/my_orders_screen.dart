import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../services/review_service.dart';
import '../widgets/skeleton_loaders.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Trigger rebuild to update empty state or filtering
    });
    _loadOrders();
  }

  Future<void> _loadOrders({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final buyerId = UserService.currentUserId;
      if (buyerId == null) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
        return;
      }
      final orders = await _orderService.getOrdersByBuyer(
        buyerId,
        forceRefresh: forceRefresh,
      );
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCustomSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.error
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  // Update order status directly in database
  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await _orderService.updateOrderStatus(orderId, status);
      if (!mounted) return;
      _showCustomSnackbar(
        'Status pesanan berhasil diubah menjadi: $status',
        AppColors.success,
      );
      _loadOrders(forceRefresh: true);
    } catch (e) {
      _showCustomSnackbar('Gagal mengubah status: $e', AppColors.error);
    }
  }

  // Delete an order
  Future<void> _deleteOrder(int orderId) async {
    try {
      await _orderService.deleteOrder(orderId);
      if (!mounted) return;
      _showCustomSnackbar('Pesanan berhasil dihapus', AppColors.primary);
      _loadOrders(forceRefresh: true);
    } catch (e) {
      _showCustomSnackbar('Gagal menghapus: $e', AppColors.error);
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> order) async {
    var rating = 5;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Beri Ulasan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () =>
                            setDialogState(() => rating = index + 1),
                      ),
                    ),
                  ),
                  TextField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ceritakan pengalamanmu...',
                      border: OutlineInputBorder(),
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
                    final reviewerId = UserService.currentUserId;
                    if (reviewerId == null) return;

                    await ReviewService().addReview(
                      productId: order['product_id'] as int,
                      orderId: order['id'] as int,
                      reviewerId: reviewerId,
                      sellerId: order['seller_id'] as int,
                      rating: rating,
                      comment: commentController.text.trim(),
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showCustomSnackbar(
                      'Ulasan berhasil disimpan',
                      AppColors.success,
                    );
                    _loadOrders();
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  List<Map<String, dynamic>> _getFilteredOrders(String status) {
    if (status == 'Semua') return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return AppColors.warning;
      case 'Diproses':
        return AppColors.info;
      case 'Dikirim':
        return AppColors.primary;
      case 'Selesai':
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Rp 0';
    final parsed = int.tryParse(value.toString()) ?? 0;
    final formatted = parsed.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'Rp $formatted';
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Semua', 'Menunggu', 'Diproses', 'Dikirim', 'Selesai'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _loadOrders,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab bar container
          Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? SkeletonLoaders.list()
                : TabBarView(
                    controller: _tabController,
                    children: tabs.map((t) {
                      final filtered = _getFilteredOrders(t);
                      if (filtered.isEmpty) {
                        return _buildEmptyState(t);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildOrderCard(order);
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tabName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: AppColors.grey300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tabName == 'Semua'
                  ? 'Anda belum memiliki transaksi pembelian apapun di Thriftin.'
                  : 'Tidak ada pesanan dengan status "$tabName" saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Menunggu';
    final orderId = order['id'] as int;
    final sellerName = order['seller_name'] ?? 'Toko Thrift';
    final productName = order['product_name'] ?? 'Produk';
    final productImg = order['product_image'] ?? '';
    final totalAmount = order['total_amount'] ?? 0;
    final createdAt = order['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      sellerName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.divider, height: 1),

          // Body Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.grey100,
                    image: productImg.startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(productImg),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !productImg.startsWith('http')
                      ? Icon(Icons.image, color: AppColors.grey400, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 barang',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Belanja',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPrice(totalAmount),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.divider, height: 1),

          // Actions Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Detail & Action Button
                    OutlinedButton(
                      onPressed: () => _showOrderDetailsBottomSheet(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (status == 'Selesai') ...[
                      OutlinedButton(
                        onPressed: () => _showReviewDialog(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Ulasan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: () =>
                          _showStatusPickerBottomSheet(orderId, status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Ubah Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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

  void _showOrderDetailsBottomSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final total = order['total_amount'] ?? 0;
        final subtotal = total - 15000;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteOrder(order['id'] as int);
                      },
                      tooltip: 'Hapus Pesanan',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('No. Invoice', 'INV/TRF/${order['id']}/024'),
                _buildDetailRow(
                  'Tanggal Transaksi',
                  _formatDate(order['created_at'] ?? ''),
                ),
                _buildDetailRow(
                  'Status',
                  order['status'] ?? 'Menunggu',
                  valueColor: _getStatusColor(order['status'] ?? ''),
                ),
                _buildDetailRow(
                  'Metode Pembayaran',
                  order['payment_method'] ?? 'Transfer',
                ),
                Divider(color: AppColors.divider, height: 24),
                Text(
                  'Rincian Pembayaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Subtotal Produk', _formatPrice(subtotal)),
                _buildDetailRow('Biaya Pengiriman', _formatPrice(15000)),
                Divider(color: AppColors.divider, height: 16),
                _buildDetailRow(
                  'Total Pembayaran',
                  _formatPrice(total),
                  isBold: true,
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusPickerBottomSheet(int orderId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final statuses = ['Menunggu', 'Diproses', 'Dikirim', 'Selesai'];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ubah Status Pesanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...statuses.map((s) {
                final isSelected = s == currentStatus;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.grey400,
                  ),
                  title: Text(
                    s,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(orderId, s);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
