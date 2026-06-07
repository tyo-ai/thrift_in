import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../services/cart_service.dart';
import '../widgets/cached_product_image.dart';
import 'duitku_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int finalPrice;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.finalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedShipping = 0; // 0=EcoExpress, 1=ThriftShip
  int _selectedPayment = 0;
  final _addressController = TextEditingController();

  static const List<_CheckoutPaymentMethod> _paymentMethods = [
    _CheckoutPaymentMethod(
      title: 'BCA Virtual Account',
      subtitle: 'BCA VA sandbox Duitku',
      icon: Icons.account_balance_rounded,
      code: 'BC',
    ),
    _CheckoutPaymentMethod(
      title: 'Mandiri Virtual Account',
      subtitle: 'Mandiri VA H2H sandbox Duitku',
      icon: Icons.account_balance_rounded,
      code: 'M2',
    ),
    _CheckoutPaymentMethod(
      title: 'BNI Virtual Account',
      subtitle: 'BNI VA sandbox Duitku',
      icon: Icons.account_balance_rounded,
      code: 'I1',
    ),
    _CheckoutPaymentMethod(
      title: 'BRI Virtual Account',
      subtitle: 'BRIVA sandbox Duitku',
      icon: Icons.account_balance_rounded,
      code: 'BR',
    ),
    _CheckoutPaymentMethod(
      title: 'OVO',
      subtitle: 'E-wallet OVO sandbox Duitku',
      icon: Icons.account_balance_wallet_rounded,
      code: 'OV',
    ),
    _CheckoutPaymentMethod(
      title: 'DANA',
      subtitle: 'E-wallet DANA sandbox Duitku',
      icon: Icons.account_balance_wallet_rounded,
      code: 'DA',
    ),
    _CheckoutPaymentMethod(
      title: 'QRIS',
      subtitle: 'QRIS sandbox Duitku',
      icon: Icons.qr_code_rounded,
      code: 'SP',
    ),
    _CheckoutPaymentMethod(
      title: 'Bayar di Tempat (COD)',
      subtitle: 'Bayar langsung saat barang diterima',
      icon: Icons.handshake_outlined,
      code: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _addressController.text = UserService.currentUser?['address'] ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _formatPrice(int value, {bool isDiscount = false}) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '${isDiscount ? '- ' : ''}Rp $formatted';
  }

  void _placeOrder() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showAppSnackBar('Alamat pengiriman harus diisi', isError: true);
      return;
    }

    if (UserService.currentUserId == null) {
      _showAppSnackBar('Silakan login terlebih dahulu', isError: true);
      return;
    }

    final sellerId = int.tryParse(
      widget.product['seller_id']?.toString() ?? '',
    );
    if (sellerId != null && sellerId == UserService.currentUserId) {
      _showAppSnackBar(
        'Kamu tidak bisa membeli barang milik sendiri',
        isError: true,
      );
      return;
    }

    final shippingCost = _selectedShipping == 0 ? 15000 : 9000;
    const serviceFee = 2000;
    const discount = 5000;
    final totalAmount =
        widget.finalPrice + shippingCost + serviceFee - discount;
    final selectedPayment = _paymentMethods[_selectedPayment];
    final paymentMethodString = selectedPayment.isCod
        ? 'COD'
        : 'Duitku ${selectedPayment.title}';
    final shippingMethod = _selectedShipping == 0 ? 'EcoExpress' : 'ThriftShip';

    if (!selectedPayment.isCod) {
      final result = await Navigator.push<DuitkuPaymentResult>(
        context,
        MaterialPageRoute(
          builder: (_) => DuitkuPaymentScreen(
            orderCode: 'THRIFTIN-${DateTime.now().millisecondsSinceEpoch}',
            productName: widget.product['name']?.toString() ?? 'Produk',
            totalAmount: totalAmount,
            paymentMethodCode: selectedPayment.code!,
          ),
        ),
      );
      if (result == null) {
        _showAppSnackBar('Pembayaran Duitku dibatalkan', isError: true);
        return;
      }
      if (!result.isPaid) {
        _showAppSnackBar('Pembayaran Duitku belum berhasil', isError: true);
        return;
      }
    }

    final orderId = await OrderService().createOrder(
      productId: widget.product['id'],
      buyerId: UserService.currentUserId!,
      sellerId: widget.product['seller_id'] ?? 1,
      totalAmount: totalAmount,
      paymentMethod: paymentMethodString,
      shippingAddress: address,
      shippingMethod: shippingMethod,
      shippingCost: shippingCost,
      serviceFee: serviceFee,
      discount: discount,
    );

    if (orderId > 0 && mounted) {
      final productId = int.tryParse(widget.product['id']?.toString() ?? '');
      if (productId != null) {
        await CartService().removeFromCart(productId);
      }
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan Berhasil!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pesanan Anda sedang diproses oleh penjual.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (mounted) {
      _showAppSnackBar('Gagal membuat pesanan', isError: true);
    }
  }

  void _showAppSnackBar(String message, {bool isError = false}) {
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
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
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

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    final imageUrl = item['imageUrl'] as String;
    final shippingCost = _selectedShipping == 0 ? 15000 : 9000;
    final totalAmount = widget.finalPrice + shippingCost + 2000 - 5000;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildCard(
              title: 'Ringkasan Pesanan',
              child: Row(
                children: [
                  CachedProductImage(
                    imageUrl: imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(10),
                    memCacheWidth: 180,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatPrice(widget.finalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Shipping Address
            _buildCard(
              title: 'Alamat Pengiriman',
              child: TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Masukkan alamat lengkap...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shipping Options
            _buildCard(
              title: 'Opsi Pengiriman',
              child: Column(
                children: [
                  _buildShippingOption(
                    index: 0,
                    title: 'EcoExpress (Regular)',
                    subtitle: '2–4 Hari Kerja',
                    price: 'Rp 15.000',
                    icon: Icons.eco_outlined,
                    iconColor: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _buildShippingOption(
                    index: 1,
                    title: 'ThriftShip Hemat',
                    subtitle: '4–7 Hari Kerja',
                    price: 'Rp 9.000',
                    icon: Icons.savings_outlined,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Payment Methods
            _buildCard(
              title: 'Metode Pembayaran',
              child: Column(
                children: List.generate(_paymentMethods.length, (index) {
                  final method = _paymentMethods[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _paymentMethods.length - 1 ? 0 : 8,
                    ),
                    child: _buildPaymentOption(
                      index,
                      method.icon,
                      method.title,
                      method.subtitle,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Bill Summary
            _buildCard(
              title: 'Rincian Pembayaran',
              child: Column(
                children: [
                  _buildBillRow(
                    'Harga Barang',
                    _formatPrice(widget.finalPrice),
                  ),
                  const SizedBox(height: 8),
                  _buildBillRow('Ongkos Kirim', _formatPrice(shippingCost)),
                  const SizedBox(height: 8),
                  _buildBillRow('Biaya Layanan', _formatPrice(2000)),
                  const SizedBox(height: 8),
                  _buildBillRow(
                    'Promo Hemat',
                    _formatPrice(5000, isDiscount: true),
                    isPromo: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppColors.divider),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatPrice(totalAmount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '🔒  Pembayaran 100% aman & terenkripsi',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildShippingOption({
    required int index,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
    required Color iconColor,
  }) {
    final selected = _selectedShipping == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedShipping = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    int index,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isPromo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isPromo ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CheckoutPaymentMethod {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? code;

  const _CheckoutPaymentMethod({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.code,
  });

  bool get isCod => code == null;
}
