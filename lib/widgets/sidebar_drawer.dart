import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/user_service.dart';
import '../services/db_helper.dart';

class SidebarDrawer extends StatefulWidget {
  const SidebarDrawer({super.key});

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer> {
  String _userName = 'Thrifter';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    if (UserService.currentUser != null) {
      setState(() {
        _userName = UserService.currentUser!['name'] ?? 'Thrifter';
      });
    } else {
      _fetchFallbackUser();
    }
  }

  Future<void> _fetchFallbackUser() async {
    try {
      final db = await DbHelper().database;
      final users = await db.query('users', orderBy: 'id DESC', limit: 1);
      if (users.isNotEmpty) {
        setState(() {
          _userName = (users.first['name'] as String?) ?? 'Thrifter';
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
             // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF8F6),
                    Color(0xFFDDF4EB),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button row
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Avatar
                  Container(
                    width: 66,
                    height: 66,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFE8EEF4),
                      backgroundImage: UserService.currentUser?['photo_path'] != null &&
                              UserService.currentUser!['photo_path'].toString().isNotEmpty
                          ? FileImage(File(UserService.currentUser!['photo_path'])) as ImageProvider
                          : NetworkImage(
                              'https://ui-avatars.com/api/?name=${_userName.replaceAll(' ', '+')}&background=E7F4F1&color=007F63&bold=true',
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Greeting
                  Text(
                    'Halo, $_userName!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.receipt_long_outlined,
              label: 'Pesanan Saya',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
            ),
            _buildMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Metode Pembayaran',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/payment-methods');
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              label: 'Pusat Bantuan',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/help-center');
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              label: 'Pengaturan',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),

            const Spacer(),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppColors.divider),
            ),
            _buildMenuItem(
              icon: Icons.logout,
              label: 'Keluar',
              onTap: () async {
                await UserService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              iconColor: AppColors.error,
              textColor: AppColors.error,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: iconColor ?? AppColors.primary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.grey300,
        size: 22,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
