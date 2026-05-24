import 'db_helper.dart';

class OrderService {
  final DbHelper _dbHelper = DbHelper();

  Future<int> createOrder({
    required int productId,
    required int buyerId,
    required int sellerId,
    required int totalAmount,
    required String paymentMethod,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('orders', {
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_amount': totalAmount,
      'status': 'Menunggu',
      'payment_method': paymentMethod,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getOrdersByBuyer(int buyerId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT orders.*, products.name as product_name, products.imageUrl as product_image, users.name as seller_name
      FROM orders
      JOIN products ON orders.product_id = products.id
      JOIN users ON orders.seller_id = users.id
      WHERE orders.buyer_id = ?
      ORDER BY orders.id DESC
    ''', [buyerId]);
  }

  Future<List<Map<String, dynamic>>> getOrdersBySeller(int sellerId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT orders.*, products.name as product_name, products.imageUrl as product_image, users.name as buyer_name
      FROM orders
      JOIN products ON orders.product_id = products.id
      JOIN users ON orders.buyer_id = users.id
      WHERE orders.seller_id = ?
      ORDER BY orders.id DESC
    ''', [sellerId]);
  }

  Future<int> updateOrderStatus(int orderId, String newStatus) async {
    final db = await _dbHelper.database;
    return await db.update(
      'orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
