import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';

class UserService {
  final DbHelper _dbHelper = DbHelper();

  static Map<String, dynamic>? currentUser;

  static int? get currentUserId => currentUser?['id'];
  static String? get currentUserRole => currentUser?['role'];

  /// Simpan sesi login ke SharedPreferences (persistent)
  Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_user_id', user['id'] as int);
    await prefs.setString('session_email', user['email'] as String);
    await prefs.setString('session_name', user['name'] as String);
    await prefs.setString('session_role', user['role'] as String);
  }

  /// Hapus sesi login dari SharedPreferences
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_user_id');
    await prefs.remove('session_email');
    await prefs.remove('session_name');
    await prefs.remove('session_role');
  }

  /// Muat sesi yang tersimpan saat app dibuka (auto-login)
  /// Return true jika ada sesi valid, false jika perlu login
  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('session_user_id');
    if (userId == null) return false;

    // Verifikasi user masih ada di database
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      currentUser = results.first;
      return true;
    }

    // User tidak ditemukan, hapus sesi
    await _clearSession();
    return false;
  }

  Future<int> registerUser({
    required String name,
    required String email,
    required String password,
    String role = 'buyer',
    String? phone,
    String? address,
  }) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'address': address,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (results.isNotEmpty) {
      currentUser = results.first;
      await _saveSession(currentUser!); // Simpan sesi
      return results.first;
    }
    currentUser = null;
    return null;
  }

  Future<int> updateProfile(int userId, String name, String phone, String address) async {
    final db = await _dbHelper.database;
    int count = await db.update(
      'users',
      {'name': name, 'phone': phone, 'address': address},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (count > 0 && currentUserId == userId) {
      // Reload current user
      final results = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (results.isNotEmpty) {
        currentUser = results.first;
        await _saveSession(currentUser!); // Update sesi tersimpan
      }
    }
    
    return count;
  }

  Future<void> logout() async {
    currentUser = null;
    await _clearSession(); // Hapus sesi tersimpan
  }
}
