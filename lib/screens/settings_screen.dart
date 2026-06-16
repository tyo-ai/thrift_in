import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/user_service.dart';
import 'complete_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    if (UserService.currentUser != null) {
      _userId = UserService.currentUserId;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    if (_userId == null) return;
    try {
      final isValidPassword = await _userService.verifyPassword(
        _userId!,
        oldPassword,
      );

      if (!mounted) return;

      if (!isValidPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kata sandi lama salah!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await _userService.changePassword(_userId!, newPassword);

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
        SnackBar(
          content: Text('Gagal mengubah kata sandi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _logoutAccount() async {
    try {
      await _userService.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda telah keluar dari akun.'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar akun: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildSectionHeader('Profil'),
                  _buildProfileCard(),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2026 Thriftin Team. All rights reserved.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
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

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(Icons.person_outline_rounded, color: AppColors.primary),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: const Text(
          'Ubah nama, foto, bio, dan info toko',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
          );
          if (!mounted) return;
          setState(() {});
        },
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
            title: const Text(
              'Ganti Kata Sandi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Perbarui kredensial sandi login Anda secara berkala',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: _showChangePasswordDialog,
          ),
          Divider(color: AppColors.divider, height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Keluar Akun',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            subtitle: const Text(
              'Keluar dari sesi login di perangkat ini',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: _showLogoutDialog,
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
            title: const Text(
              'Syarat & Ketentuan Layanan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: () {
              Navigator.pushNamed(context, '/terms');
            },
          ),
          Divider(color: AppColors.divider, height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
            title: const Text(
              'Kebijakan Privasi Data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: () {
              Navigator.pushNamed(context, '/privacy');
            },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Ganti Kata Sandi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi Lama',
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Harap isi kata sandi lama'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi Baru',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Harap isi kata sandi baru';
                    }
                    if (v.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Sandi Baru',
                  ),
                  validator: (v) {
                    if (v != newPasswordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
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
                  _changePassword(
                    oldPasswordController.text,
                    newPasswordController.text,
                  );
                }
              },
              child: const Text(
                'Ubah Sandi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar Akun?',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Anda akan keluar dari akun di perangkat ini. Data profil, pesanan, produk, dan chat tetap aman di sistem Thriftin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logoutAccount();
              },
              child: const Text(
                'Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
