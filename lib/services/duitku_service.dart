import 'supabase_config.dart';

class DuitkuService {
  Future<DuitkuPaymentSession> createSandboxSession({
    required String orderCode,
    required int grossAmount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? productName,
    String? paymentMethod,
  }) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'create-duitku-transaction',
      body: {
        'merchantOrderId': orderCode,
        'paymentAmount': grossAmount,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
        'productDetails': productName ?? 'Produk Thriftin',
        'customerVaName': customerName,
        'email': customerEmail,
        'phoneNumber': customerPhone ?? '',
        'itemDetails': [
          {
            'name': productName ?? 'Produk Thriftin',
            'price': grossAmount,
            'quantity': 1,
          },
        ],
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return DuitkuPaymentSession.fromMap(data);
  }
}

class DuitkuPaymentSession {
  final String merchantOrderId;
  final String reference;
  final String paymentUrl;
  final String statusCode;
  final String statusMessage;

  DuitkuPaymentSession({
    required this.merchantOrderId,
    required this.reference,
    required this.paymentUrl,
    required this.statusCode,
    required this.statusMessage,
  });

  factory DuitkuPaymentSession.fromMap(Map<String, dynamic> data) {
    return DuitkuPaymentSession(
      merchantOrderId: data['merchantOrderId']?.toString() ?? '',
      reference: data['reference']?.toString() ?? '',
      paymentUrl: data['paymentUrl']?.toString() ?? '',
      statusCode: data['statusCode']?.toString() ?? '',
      statusMessage: data['statusMessage']?.toString() ?? '',
    );
  }
}
