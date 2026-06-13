import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class UserService {
  static Map<String, dynamic>? currentUser;
  static const Duration _userCacheTtl = Duration(minutes: 5);
  static final Map<int, _UserCacheEntry> _userCache = {};

  static int? get currentUserId => currentUser?['id'] as int?;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  bool _passwordMatches(String stored, String input) {
    return stored == input || stored == _hashPassword(input);
  }

  Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_user_id', user['id'] as int);
    await prefs.setString('session_email', user['email'] as String);
    await prefs.setString('session_name', user['name'] as String);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_user_id');
    await prefs.remove('session_email');
    await prefs.remove('session_name');
  }

  Future<Map<String, dynamic>?> _getUserById(int userId) async {
    final cached = _userCache[userId];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _userCacheTtl) {
      return Map<String, dynamic>.from(cached.user);
    }

    final result = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (result == null) return null;

    final user = Map<String, dynamic>.from(result);
    _userCache[userId] = _UserCacheEntry(user);
    return Map<String, dynamic>.from(user);
  }

  Future<Map<String, dynamic>?> getUserById(int userId) => _getUserById(userId);

  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('session_user_id');
    if (userId == null) return false;

    final user = await _getUserById(userId);
    if (user != null) {
      currentUser = user;
      _userCache[userId] = _UserCacheEntry(user);
      return true;
    }

    await _clearSession();
    return false;
  }

  Future<int> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    try {
      final result = await SupabaseConfig.client
          .from('users')
          .insert({
            'name': name,
            'email': email,
            'password': _hashPassword(password),
            'phone': phone,
            'address': address,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return result['id'] as int;
    } catch (_) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final result = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (result == null ||
        !_passwordMatches(result['password']?.toString() ?? '', password)) {
      currentUser = null;
      return null;
    }

    currentUser = Map<String, dynamic>.from(result);
    _userCache[currentUser!['id'] as int] = _UserCacheEntry(currentUser!);
    if (currentUser!['password'] == password) {
      await changePassword(currentUser!['id'] as int, password);
      currentUser!['password'] = _hashPassword(password);
    }
    await _saveSession(currentUser!);
    return currentUser;
  }

  Future<int> updateProfile(
    int userId,
    String name,
    String phone,
    String address,
  ) async {
    await SupabaseConfig.client
        .from('users')
        .update({'name': name, 'phone': phone, 'address': address})
        .eq('id', userId);

    await _refreshCurrentUser(userId);
    return 1;
  }

  Future<int> updateBio(int userId, String bio) async {
    await SupabaseConfig.client
        .from('users')
        .update({'bio': bio})
        .eq('id', userId);

    await _refreshCurrentUser(userId);
    return 1;
  }

  Future<int> updateBioAndPhoto(
    int userId,
    String bio,
    String? photoPath, {
    String? phone,
    String? address,
    String? name,
    String? gender,
    String? birthDate,
  }) async {
    final data = <String, dynamic>{'bio': bio};
    if (photoPath != null) {
      data['photo_path'] = photoPath.startsWith('http')
          ? photoPath
          : await uploadProfilePhoto(
              userId: userId,
              imageFile: File(photoPath),
            );
    }
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender;
    if (birthDate != null) data['birth_date'] = birthDate;

    await SupabaseConfig.client.from('users').update(data).eq('id', userId);
    await _refreshCurrentUser(userId);
    return 1;
  }

  Future<String> uploadProfilePhoto({
    required int userId,
    required File imageFile,
  }) async {
    final extension = imageFile.path.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty || extension.length > 5
        ? 'jpg'
        : extension;
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final objectPath =
        '$userId/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';

    await SupabaseConfig.client.storage
        .from('profile-photos')
        .uploadBinary(
          objectPath,
          await imageFile.readAsBytes(),
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        )
        .timeout(const Duration(seconds: 25));

    return SupabaseConfig.client.storage
        .from('profile-photos')
        .getPublicUrl(objectPath);
  }

  Future<void> changePassword(int userId, String newPassword) async {
    await SupabaseConfig.client
        .from('users')
        .update({'password': _hashPassword(newPassword)})
        .eq('id', userId);
  }

  Future<bool> verifyPassword(int userId, String password) async {
    final result = await SupabaseConfig.client
        .from('users')
        .select('password')
        .eq('id', userId)
        .maybeSingle();
    if (result == null) return false;
    return _passwordMatches(result['password']?.toString() ?? '', password);
  }

  Future<void> deleteUser(int userId) async {
    await SupabaseConfig.client.from('users').delete().eq('id', userId);
    if (currentUserId == userId) {
      await logout();
    }
  }

  Future<void> _refreshCurrentUser(int userId) async {
    if (currentUserId != userId) return;

    final user = await _getUserById(userId);
    if (user != null) {
      currentUser = user;
      _userCache[userId] = _UserCacheEntry(user);
      await _saveSession(user);
    }
  }

  Future<void> logout() async {
    currentUser = null;
    _userCache.clear();
    await _clearSession();
  }
}

class _UserCacheEntry {
  final DateTime createdAt;
  final Map<String, dynamic> user;

  _UserCacheEntry(this.user) : createdAt = DateTime.now();
}
