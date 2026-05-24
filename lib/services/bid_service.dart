import 'db_helper.dart';

class BidService {
  final DbHelper _dbHelper = DbHelper();

  Future<int> placeBid({
    required int productId,
    required int buyerId,
    required int amount,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('bids', {
      'product_id': productId,
      'buyer_id': buyerId,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getBidsForItem(int productId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT bids.*, users.name as buyer_name 
      FROM bids 
      JOIN users ON bids.buyer_id = users.id 
      WHERE product_id = ? 
      ORDER BY amount DESC, bids.id ASC
    ''', [productId]);
  }

  Future<int> getHighestBid(int productId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'bids',
      columns: ['MAX(amount) as max_amount'],
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    if (results.isNotEmpty && results.first['max_amount'] != null) {
      return (results.first['max_amount'] as num).toInt();
    }
    return 0;
  }
}
