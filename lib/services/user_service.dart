import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_notification_service.dart';
import 'supabase_config.dart';

class UserService {
  static Map<String, dynamic>? currentUser;
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '152645975944-8lnfr5lhijp59640d7bd19edkbfs47ic.apps.googleusercontent.com',
  );
  static const googleRedirectUrl = 'thriftin://login-callback';
  static const Duration _userCacheTtl = Duration(minutes: 5);
  static final Map<int, _UserCacheEntry> _userCache = {};
  static bool _googleSignInReady = false;

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
    unawaited(
      FirebaseNotificationService.instance
          .registerCurrentDevice(user['id'] as int)
          .catchError((error) {
            debugPrint('FCM registration skipped after login: $error');
          }),
    );
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
    if (userId == null) {
      final oauthUser = await syncSupabaseAuthUser();
      return oauthUser != null;
    }

    final user = await _getUserById(userId);
    if (user != null) {
      currentUser = user;
      _userCache[userId] = _UserCacheEntry(user);
      _registerFcmToken(userId);
      return true;
    }

    await _clearSession();
    return false;
  }

  Future<bool> signInWithGoogle() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await _signInWithNativeGoogle();
        return true;
      } on PlatformException catch (error) {
        if (error.code != 'channel-error') rethrow;

        return _signInWithGoogleOAuth();
      }
    }

    return _signInWithGoogleOAuth();
  }

  Future<bool> _signInWithGoogleOAuth() {
    return SupabaseConfig.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: googleRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInReady) return;

    await GoogleSignIn.instance.initialize(serverClientId: googleWebClientId);
    _googleSignInReady = true;
  }

  Future<void> _signInWithNativeGoogle() async {
    await _ensureGoogleSignInInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw Exception('Google tidak mengembalikan ID token');
    }

    final authorization =
        await account.authorizationClient.authorizationForScopes(
          const <String>[],
        ) ??
        await account.authorizationClient.authorizeScopes(const <String>[]);

    await SupabaseConfig.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  Future<Map<String, dynamic>?> syncSupabaseAuthUser() async {
    final authUser = SupabaseConfig.client.auth.currentUser;
    final email = authUser?.email?.trim().toLowerCase();
    if (authUser == null || email == null || email.isEmpty) {
      return null;
    }

    final metadata = authUser.userMetadata ?? <String, dynamic>{};
    final displayName =
        (metadata['full_name'] ?? metadata['name'] ?? email.split('@').first)
            .toString()
            .trim();
    final avatarUrl = (metadata['avatar_url'] ?? metadata['picture'])
        ?.toString()
        .trim();

    final existing = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    Map<String, dynamic> user;
    if (existing == null) {
      final created = await SupabaseConfig.client
          .from('users')
          .insert({
            'name': displayName.isEmpty ? 'Pengguna ThriftIn' : displayName,
            'email': email,
            'password': _hashPassword('google:${authUser.id}'),
            'photo_path': avatarUrl?.isEmpty == false ? avatarUrl : null,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      user = Map<String, dynamic>.from(created);
    } else {
      user = Map<String, dynamic>.from(existing);
      final updates = <String, dynamic>{};
      final currentPhoto = user['photo_path']?.toString().trim() ?? '';
      if (currentPhoto.isEmpty && avatarUrl != null && avatarUrl.isNotEmpty) {
        updates['photo_path'] = avatarUrl;
      }
      if ((user['name']?.toString().trim() ?? '').isEmpty &&
          displayName.isNotEmpty) {
        updates['name'] = displayName;
      }
      if (updates.isNotEmpty) {
        final updated = await SupabaseConfig.client
            .from('users')
            .update(updates)
            .eq('id', user['id'])
            .select()
            .single();
        user = Map<String, dynamic>.from(updated);
      }
    }

    currentUser = user;
    _userCache[user['id'] as int] = _UserCacheEntry(user);
    await _saveSession(user);
    return user;
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

  void _registerFcmToken(int userId) {
    unawaited(
      FirebaseNotificationService.instance
          .registerCurrentDevice(userId)
          .catchError((error) {
            debugPrint('FCM registration skipped: $error');
          }),
    );
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
    final userId = currentUserId;
    unawaited(
      FirebaseNotificationService.instance
          .removeCurrentDeviceToken(userId: userId)
          .catchError((error) {
            debugPrint('FCM token cleanup skipped during logout: $error');
          }),
    );
    currentUser = null;
    _userCache.clear();
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {
      // Local logout should still continue if the OAuth session is unavailable.
    }
    await _clearSession();
  }
}

class _UserCacheEntry {
  final DateTime createdAt;
  final Map<String, dynamic> user;

  _UserCacheEntry(this.user) : createdAt = DateTime.now();
}
