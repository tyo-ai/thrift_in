import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../services/db_helper.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final buyerId = UserService.currentUserId ?? 2; // Fallback to buyer Andhika (2)
      final orders = await _orderService.getOrdersByBuyer(buyerId);
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

  // Generate a random mock order to demonstrate database writing
  Future<void> _addMockOrder() async {
    try {
      final db = await DbHelper().database;
      // Get products to link to the order
      final products = await db.query('products');
      if (products.isEmpty) return;

      // Select a random product
      final randomProduct = (products..shuffle()).first;
      final productId = randomProduct['id'] as int;
      final sellerId = randomProduct['seller_id'] as int;
      final priceString = randomProduct['price'] as String;
      final price = int.tryParse(priceString) ?? 150000;

      final buyerId = UserService.currentUserId ?? 2;
      final paymentMethods = ['GoPay', 'DANA', 'BCA Virtual Account', 'Mandiri'];
      final paymentMethod = (paymentMethods..shuffle()).first;
      
      final statuses = ['Menunggu', 'Diproses', 'Dikirim', 'Selesai'];
      final status = (statuses..shuffle()).first;

      await db.insert('orders', {
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'total_amount': price + 15000, // include shipping mock
        'status': status,
        'payment_method': paymentMethod,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambah pesanan dummy baru!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah pesanan dummy: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Update order status directly in database
  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await _orderService.updateOrderStatus(orderId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pesanan berhasil diubah menjadi: $status'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Delete an order
  Future<void> _deleteOrder(int orderId) async {
    try {
      final db = await DbHelper().database;
      await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan berhasil dihapus'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
            tooltip: 'Tambah Pesanan Dummy',
            onPressed: _addMockOrder,
          ),
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
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addMockOrder,
              icon: Icon(Icons.add, size: 18, color: Colors.white),
              label: Text('Buat Pesanan Dummy', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        ? DecorationImage(image: NetworkImage(productImg), fit: BoxFit.cover)
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showStatusPickerBottomSheet(orderId, status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Ubah Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
      builder: (context) {
        final total = order['total_amount'] ?? 0;
        final subtotal = total - 15000;
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
              _buildDetailRow('Tanggal Transaksi', _formatDate(order['created_at'] ?? '')),
              _buildDetailRow('Status', order['status'] ?? 'Menunggu', valueColor: _getStatusColor(order['status'] ?? '')),
              _buildDetailRow('Metode Pembayaran', order['payment_method'] ?? 'Transfer'),
              Divider(color: AppColors.divider, height: 24),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              _buildDetailRow('Subtotal Produk', _formatPrice(subtotal)),
              _buildDetailRow('Biaya Pengiriman', _formatPrice(15000)),
              Divider(color: AppColors.divider, height: 16),
              _buildDetailRow('Total Pembayaran', _formatPrice(total), isBold: true, valueColor: AppColors.primary),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Tutup', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
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
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.grey400,
                  ),
                  title: Text(
                    s,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
