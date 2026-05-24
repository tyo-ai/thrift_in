import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'thriftin.db');

    return await openDatabase(
      pathString,
      version: 6,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('DROP TABLE IF EXISTS products');
          await db.execute('DROP TABLE IF EXISTS live_bids');
          await db.execute('DROP TABLE IF EXISTS bids');
          await db.execute('DROP TABLE IF EXISTS orders');
          await db.execute('DROP TABLE IF EXISTS notifications');
          await db.execute('DROP TABLE IF EXISTS payment_methods');
          await db.execute('DROP TABLE IF EXISTS help_messages');
          await _createTables(db);
          await _seedData(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'buyer',
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seller_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price TEXT NOT NULL,
        rating REAL DEFAULT 0.0,
        reviewCount INTEGER DEFAULT 0,
        category TEXT DEFAULT 'Semua',
        condition TEXT DEFAULT 'Pernah Dipakai',
        storeName TEXT NOT NULL,
        location TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        isFavorite INTEGER DEFAULT 0,
        badge TEXT,
        isBid INTEGER DEFAULT 0,
        end_time TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        buyer_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        buyer_id INTEGER NOT NULL,
        seller_id INTEGER NOT NULL,
        total_amount INTEGER NOT NULL,
        status TEXT DEFAULT 'Menunggu',
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        iconName TEXT NOT NULL,
        iconColorHex TEXT NOT NULL,
        iconBgColorHex TEXT NOT NULL,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        description TEXT NOT NULL,
        isUnread INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        account_number TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE help_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        category TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedData(Database db) async {
    // Inject users
    final List<Map<String, dynamic>> users = [
      {
        'id': 1,
        'name': 'Keandra',
        'email': 'seller1@thrift.in',
        'password': 'password123',
        'role': 'seller',
        'phone': '081234567890',
        'address': 'Jl. Malang Raya No 1',
        'created_at': DateTime.now().toIso8601String()
      },
      {
        'id': 2,
        'name': 'Andhika',
        'email': 'buyer1@thrift.in',
        'password': 'password123',
        'role': 'buyer',
        'phone': '081298765432',
        'address': 'Jl. Surakarta No 5',
        'created_at': DateTime.now().toIso8601String()
      }
    ];

    for (var u in users) {
      await db.insert('users', u);
    }

    // Hitung waktu selesai lelang (besok, lusa)
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1)).toIso8601String();
    final nextWeek = now.add(const Duration(days: 7)).toIso8601String();

    // Inject products
    final List<Map<String, dynamic>> products = [
      {
        'id': 1,
        'seller_id': 1,
        'imageUrl': 'https://picsum.photos/seed/cozyknit/300/300',
        'rating': 4.9,
        'reviewCount': 127,
        'name': 'Cozy Knit Cardigan Vintage',
        'category': 'Pakaian',
        'condition': 'Pernah Dipakai',
        'storeName': 'Keandra\'s Attic',
        'location': 'Malang',
        'price': '225000',
        'isFavorite': 0,
        'badge': 'Sangat Bagus',
        'isBid': 0,
      },
      {
        'id': 2,
        'seller_id': 1,
        'imageUrl': 'https://picsum.photos/seed/silverjewel/300/300',
        'rating': 4.8,
        'reviewCount': 89,
        'name': 'Minimalist Silver Bracelet Set',
        'category': 'Aksesoris',
        'condition': 'Baru',
        'storeName': 'Kenzie\'s Attic',
        'location': 'Tangerang',
        'price': '450000',
        'isFavorite': 0,
        'badge': 'Langka',
        'isBid': 0,
      },
      {
        'id': 3,
        'seller_id': 1,
        'imageUrl': 'https://picsum.photos/seed/levis-trucker/300/300',
        'rating': 4.9,
        'reviewCount': 84,
        'name': 'Levi\'s 750S Trucker Jacket',
        'category': 'Pakaian',
        'condition': 'Pernah Dipakai',
        'storeName': 'Premium',
        'location': 'Jakarta',
        'price': '1250000',
        'isFavorite': 0,
        'badge': 'Premium',
        'isBid': 1,
        'end_time': tomorrow,
      },
      {
        'id': 4,
        'seller_id': 1,
        'imageUrl': 'https://picsum.photos/seed/harvard-varsity/300/300',
        'rating': 4.9,
        'reviewCount': 11,
        'name': 'Harvard Vintage Varsity',
        'category': 'Pakaian',
        'condition': 'Pernah Dipakai',
        'storeName': 'Vintage Heritage',
        'location': 'Surabaya',
        'price': '550000',
        'isFavorite': 0,
        'badge': 'Langka',
        'isBid': 1,
        'end_time': nextWeek,
      },
      {
        'id': 5,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=700',
        'rating': 4.8,
        'reviewCount': 42,
        'name': '90s Olive Bomber Jacket',
        'category': 'Pakaian',
        'condition': 'Sangat Bagus',
        'storeName': 'Vintage Store',
        'location': 'Bandung',
        'price': '350000',
        'isFavorite': 0,
        'badge': 'TERSEDIA',
        'isBid': 0,
      },
      {
        'id': 6,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=700',
        'rating': 4.9,
        'reviewCount': 15,
        'name': 'Levi’s 70505 Trucker 1970',
        'category': 'Pakaian',
        'condition': 'Pernah Dipakai',
        'storeName': 'Retro Denim',
        'location': 'Bandung',
        'price': '1250000',
        'isFavorite': 0,
        'badge': 'LELANG',
        'isBid': 1,
        'end_time': tomorrow,
      },
      {
        'id': 7,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1520975954732-35dd22299614?w=700',
        'rating': 4.7,
        'reviewCount': 28,
        'name': 'Genuine Leather Biker Jacket',
        'category': 'Pakaian',
        'condition': 'Sangat Bagus',
        'storeName': 'Garut Leather',
        'location': 'Garut',
        'price': '890000',
        'isFavorite': 0,
        'badge': 'TERSEDIA',
        'isBid': 0,
      },
      {
        'id': 8,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1543076447-215ad9ba6923?w=700',
        'rating': 4.6,
        'reviewCount': 19,
        'name': 'Neon Retro Windbreaker Jacket',
        'category': 'Pakaian',
        'condition': 'Baru',
        'storeName': 'Neon Retro',
        'location': 'Jakarta',
        'price': '225000',
        'isFavorite': 0,
        'badge': 'TERSEDIA',
        'isBid': 0,
      },
      {
        'id': 9,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1548624313-0396c75d7092?w=700',
        'rating': 4.9,
        'reviewCount': 34,
        'name': 'Classic London Trench Jacket',
        'category': 'Pakaian',
        'condition': 'Sangat Bagus',
        'storeName': 'London Style',
        'location': 'Surakarta',
        'price': '1100000',
        'isFavorite': 0,
        'badge': 'TERSEDIA',
        'isBid': 0,
      },
      {
        'id': 10,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600',
        'rating': 4.8,
        'reviewCount': 15,
        'name': 'Vintage Converse Chuck 70',
        'category': 'Sepatu',
        'condition': 'Pernah Dipakai',
        'storeName': 'Sneaker Alley',
        'location': 'Jakarta',
        'price': '450000',
        'isFavorite': 0,
        'badge': 'Sangat Bagus',
        'isBid': 0,
      },
      {
        'id': 11,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
        'rating': 4.7,
        'reviewCount': 9,
        'name': 'Heritage Brown Leather Bag',
        'category': 'Tas',
        'condition': 'Sangat Bagus',
        'storeName': 'Leather Works',
        'location': 'Yogyakarta',
        'price': '1200000',
        'isFavorite': 0,
        'badge': 'Langka',
        'isBid': 0,
      },
      {
        'id': 12,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=600',
        'rating': 4.6,
        'reviewCount': 12,
        'name': 'Sony Walkman WM-EX1 cassette player',
        'category': 'Elektronik',
        'condition': 'Pernah Dipakai',
        'storeName': 'Retro Tech',
        'location': 'Surakarta',
        'price': '950000',
        'isFavorite': 0,
        'badge': 'Vintage',
        'isBid': 0,
      },
      {
        'id': 13,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=600',
        'rating': 4.9,
        'reviewCount': 22,
        'name': 'Doc Martens 1461 Classic Black Oxford',
        'category': 'Sepatu',
        'condition': 'Sangat Bagus',
        'storeName': 'Bootmaker',
        'location': 'Bandung',
        'price': '1850000',
        'isFavorite': 0,
        'badge': 'Premium',
        'isBid': 0,
      },
      {
        'id': 14,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
        'rating': 4.8,
        'reviewCount': 18,
        'name': 'Vintage Gucci Shoulder Bag',
        'category': 'Tas',
        'condition': 'Sangat Bagus',
        'storeName': 'Lux Vault',
        'location': 'Jakarta',
        'price': '3450000',
        'isFavorite': 0,
        'badge': 'Langka',
        'isBid': 0,
      },
      {
        'id': 15,
        'seller_id': 1,
        'imageUrl': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600',
        'rating': 4.7,
        'reviewCount': 8,
        'name': 'Fujifilm FinePix Retro DigiCam',
        'category': 'Elektronik',
        'condition': 'Baru',
        'storeName': 'Cam Corner',
        'location': 'Surabaya',
        'price': '1150000',
        'isFavorite': 0,
        'badge': 'Baru',
        'isBid': 0,
      }
    ];

    for (var p in products) {
      await db.insert('products', p);
    }

    // Inject notifications
    final List<Map<String, dynamic>> notifs = [
      {
        'iconName': 'gavel',
        'iconColorHex': 'FFFF8A65',
        'iconBgColorHex': 'FFFDF3F0',
        'title': 'Lelang Anda Terlampaui!',
        'time': 'Baru saja',
        'description': 'Seseorang menawar Rp250.000 untuk "Vintage Levi\'s 501". Segera naikkan tawaran mu, sebelum terlambat!',
        'isUnread': 1,
      },
      {
        'iconName': 'check_circle',
        'iconColorHex': 'FF10B981',
        'iconBgColorHex': 'FFE6F7F0',
        'title': 'Pembayaran Berhasil',
        'time': '3 Menit lalu',
        'description': 'Dana sebesar Rp450.000 telah masuk ke Rekening Bersama Thriftin untuk transaksi #TX-9321',
        'isUnread': 1,
      }
    ];

    for (var n in notifs) {
      await db.insert('notifications', n);
    }

    // Inject orders
    final List<Map<String, dynamic>> orders = [
      {
        'product_id': 1,
        'buyer_id': 2,
        'seller_id': 1,
        'total_amount': 225000,
        'status': 'Diproses',
        'payment_method': 'GoPay',
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String()
      },
      {
        'product_id': 2,
        'buyer_id': 2,
        'seller_id': 1,
        'total_amount': 450000,
        'status': 'Menunggu',
        'payment_method': 'BCA Virtual Account',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()
      },
      {
        'product_id': 3,
        'buyer_id': 2,
        'seller_id': 1,
        'total_amount': 1250000,
        'status': 'Selesai',
        'payment_method': 'DANA',
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()
      }
    ];

    for (var o in orders) {
      await db.insert('orders', o);
    }

    // Inject payment methods
    final List<Map<String, dynamic>> methods = [
      {
        'type': 'E-Wallet',
        'name': 'GoPay',
        'account_number': '0812****5432',
        'is_default': 1,
        'image_url': ''
      },
      {
        'type': 'Virtual Account',
        'name': 'BCA Virtual Account',
        'account_number': '88012******932',
        'is_default': 0,
        'image_url': ''
      },
      {
        'type': 'E-Wallet',
        'name': 'DANA',
        'account_number': '0812****5432',
        'is_default': 0,
        'image_url': ''
      }
    ];

    for (var m in methods) {
      await db.insert('payment_methods', m);
    }
  }
}
