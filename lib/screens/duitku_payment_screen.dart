import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/duitku_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

class DuitkuPaymentScreen extends StatefulWidget {
  final String orderCode;
  final String productName;
  final int totalAmount;
  final String paymentMethodCode;

  const DuitkuPaymentScreen({
    super.key,
    required this.orderCode,
    required this.productName,
    required this.totalAmount,
    required this.paymentMethodCode,
  });

  @override
  State<DuitkuPaymentScreen> createState() => _DuitkuPaymentScreenState();
}

class _DuitkuPaymentScreenState extends State<DuitkuPaymentScreen> {
  final DuitkuService _duitkuService = DuitkuService();
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _openPayment();
  }

  Future<void> _openPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = UserService.currentUser ?? {};
      final session = await _duitkuService.createSandboxSession(
        orderCode: widget.orderCode,
        grossAmount: widget.totalAmount,
        customerName: user['name']?.toString() ?? 'Thriftin User',
        customerEmail: user['email']?.toString() ?? 'sandbox@thriftin.local',
        customerPhone: user['phone']?.toString(),
        productName: widget.productName,
        paymentMethod: widget.paymentMethodCode,
      );

      if (session.paymentUrl.isEmpty) {
        throw Exception(session.statusMessage);
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final result = _resultFromUri(Uri.tryParse(request.url), session);
              if (result != null) {
                Navigator.pop(context, result);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onPageFinished: (url) {
              final result = _resultFromUri(Uri.tryParse(url), session);
              if (result != null && mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(session.paymentUrl));

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Gagal membuka pembayaran Duitku. Pastikan Edge Function, merchant code, dan API key sandbox sudah diset.';
        _isLoading = false;
      });
    }
  }

  DuitkuPaymentResult? _resultFromUri(Uri? uri, DuitkuPaymentSession session) {
    if (uri == null) return null;
    final isReturnUrl =
        uri.host == 'thriftin.local' && uri.path.contains('/duitku/return');
    if (!isReturnUrl) return null;

    final resultCode =
        uri.queryParameters['resultCode'] ??
        uri.queryParameters['result'] ??
        uri.queryParameters['status'] ??
        '';
    return DuitkuPaymentResult(
      merchantOrderId:
          uri.queryParameters['merchantOrderId'] ?? session.merchantOrderId,
      reference: uri.queryParameters['reference'] ?? session.reference,
      resultCode: resultCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Duitku Sandbox',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? _buildError()
          : controller == null
          ? _buildError()
          : WebViewWidget(controller: controller),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payment_outlined,
              color: AppColors.textHint,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Pembayaran Duitku belum bisa dibuka.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _openPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class DuitkuPaymentResult {
  final String merchantOrderId;
  final String reference;
  final String resultCode;

  DuitkuPaymentResult({
    required this.merchantOrderId,
    required this.reference,
    required this.resultCode,
  });

  bool get isPaid =>
      resultCode == '00' || resultCode.toLowerCase() == 'success';
}
