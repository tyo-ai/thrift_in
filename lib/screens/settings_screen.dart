import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/user_service.dart';
import '../services/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  
  // Profile Form Controllers
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // App Toggles state
  bool _pushNotifications = true;
  bool _biometrics = false;
  bool _darkMode = false;
  
  bool _isLoading = true;
  String _userEmail = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    // Load current user profile from UserService, fallback to Andhika in database if none is active
    if (UserService.currentUser != null) {
      _userId = UserService.currentUserId;
      _userEmail = UserService.currentUser!['email'] ?? '';
      _nameController.text = UserService.currentUser!['name'] ?? '';
      _phoneController.text = UserService.currentUser!['phone'] ?? '';
      _addressController.text = UserService.currentUser!['address'] ?? '';
      setState(() => _isLoading = false);
    } else {
      try {
        final db = await DbHelper().database;
        final users = await db.query('users', where: 'id = ?', whereArgs: [2], limit: 1);
        if (users.isNotEmpty) {
          final user = users.first;
          _userId = 2;
          _userEmail = user['email'] as String? ?? '';
          _nameController.text = user['name'] as String? ?? '';
          _phoneController.text = user['phone'] as String? ?? '';
          _addressController.text = user['address'] as String? ?? '';
        }
        setState(() => _isLoading = false);
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (_userId == null) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    try {
      await _userService.updateProfile(_userId!, name, phone, address);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil Anda berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Reload profile to ensure UserService.currentUser is loaded correctly
      _loadUserProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    if (_userId == null) return;
    try {
      final db = await DbHelper().database;
      // First verify old password
      final results = await db.query(
        'users',
        where: 'id = ? AND password = ?',
        whereArgs: [_userId, oldPassword],
      );

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kata sandi lama salah!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Update password
      await db.update(
        'users',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [_userId],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kata sandi berhasil diubah!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah kata sandi: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (_userId == null) return;
    try {
      final db = await DbHelper().database;
      await db.delete('users', where: 'id = ?', whereArgs: [_userId]);
      
      if (!mounted) return;

      _userService.logout();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Akun Anda telah berhasil dihapus secara permanen.'),
          backgroundColor: AppColors.primary,
        ),
      );
      
      // Redirect to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus akun: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section Header
                  _buildSectionHeader('Profil Saya'),
                  _buildProfileCard(),
                  const SizedBox(height: 24),

                  // App Settings Section
                  _buildSectionHeader('Preferensi Aplikasi'),
                  _buildAppSettingsCard(),
                  const SizedBox(height: 24),

                  // Security Section
                  _buildSectionHeader('Keamanan Akun'),
                  _buildSecurityCard(),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionHeader('Info Aplikasi'),
                  _buildAboutCard(),
                  const SizedBox(height: 32),

                  // App Version Text
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Thriftin App v1.0.3-Stable',
                          style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2026 Thriftin Team. All rights reserved.',
                          style: TextStyle(fontSize: 10, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            // Static Email
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alamat Email', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(_userEmail, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                labelStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                labelStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor telepon tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Alamat Pengiriman',
                labelStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat tidak boleh kosong' : null,
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saveProfileChanges,
                icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                label: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notifikasi Push', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            subtitle: const Text('Terima pembaruan penawaran lelang & status pesanan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: _pushNotifications,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          Divider(color: AppColors.divider, height: 1),
          SwitchListTile(
            title: const Text('Keamanan Biometrik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            subtitle: const Text('Gunakan sidik jari atau Face ID untuk masuk cepat', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: _biometrics,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _biometrics = v),
          ),
          Divider(color: AppColors.divider, height: 1),
          SwitchListTile(
            title: const Text('Tema Gelap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            subtitle: const Text('Aktifkan visual tema gelap untuk menghemat mata Anda', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            value: _darkMode,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.key_outlined, color: AppColors.primary),
            title: const Text('Ganti Kata Sandi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            subtitle: const Text('Perbarui kredensial sandi login Anda secara berkala', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: _showChangePasswordDialog,
          ),
          Divider(color: AppColors.divider, height: 1),
          ListTile(
            leading: const Icon(Icons.no_accounts_outlined, color: AppColors.error),
            title: const Text('Hapus Akun Permanen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
            subtitle: const Text('Menghapus data akun Anda secara permanen dari sistem', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.description_outlined, color: AppColors.primary),
            title: const Text('Syarat & Ketentuan Layanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: () {},
          ),
          Divider(color: AppColors.divider, height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
            title: const Text('Kebijakan Privasi Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ganti Kata Sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata Sandi Lama'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Harap isi kata sandi lama' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Kata Sandi Baru'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Harap isi kata sandi baru';
                    if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Konfirmasi Sandi Baru'),
                  validator: (v) {
                    if (v != newPasswordController.text) return 'Kata sandi tidak cocok';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  _changePassword(oldPasswordController.text, newPasswordController.text);
                }
              },
              child: const Text('Ubah Sandi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hapus Akun Permanen?', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
          content: const Text(
            'Tindakan ini tidak dapat dibatalkan. Semua data profil, riwayat pesanan, lelang, dan akun Anda akan dihapus secara permanen dari sistem Thriftin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              child: const Text('Ya, Hapus Permanen', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
