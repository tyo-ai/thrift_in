import 'db_helper.dart';

class ProductService {
  final DbHelper _dbHelper = DbHelper();

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await _dbHelper.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getProductsBySeller(int sellerId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'seller_id = ?',
      whereArgs: [sellerId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    if (query.trim().isEmpty) {
      return await db.query('products', orderBy: 'id DESC');
    }
    
    final keywords = query.trim().split(RegExp(r'\s+'));
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];
    
    for (var keyword in keywords) {
      if (keyword.trim().isEmpty) continue;
      final kw = keyword.toLowerCase();
      if (kw == 'jaket' || kw == 'jacket') {
        whereClauses.add('(LOWER(name) LIKE ? OR LOWER(name) LIKE ? OR LOWER(category) LIKE ?)');
        whereArgs.addAll(['%jaket%', '%jacket%', '%pakaian%']);
      } else {
        whereClauses.add('(LOWER(name) LIKE ? OR LOWER(category) LIKE ? OR LOWER(condition) LIKE ? OR LOWER(storeName) LIKE ? OR LOWER(location) LIKE ?)');
        final arg = '%$kw%';
        whereArgs.addAll([arg, arg, arg, arg, arg]);
      }
    }
    
    if (whereClauses.isEmpty) {
      return await db.query('products', orderBy: 'id DESC');
    }
    
    final whereString = whereClauses.join(' AND ');
    
    return await db.query(
      'products',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
  }

  Future<int> addProduct({
    required int sellerId,
    required String name,
    required String price,
    double rating = 0.0,
    int reviewCount = 0,
    String category = 'Semua',
    String condition = 'Pernah Dipakai',
    required String storeName,
    required String location,
    required String imageUrl,
    String? badge,
    bool isBid = false,
    String? endTime,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('products', {
      'seller_id': sellerId,
      'name': name,
      'price': price,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      'condition': condition,
      'storeName': storeName,
      'location': location,
      'imageUrl': imageUrl,
      'isFavorite': 0,
      'badge': badge,
      'isBid': isBid ? 1 : 0,
      'end_time': endTime,
    });
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
  }

  Future<int> toggleFavorite(int id, bool isFav) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'isFavorite': isFav ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
