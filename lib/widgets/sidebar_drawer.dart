import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'user_avatar.dart';

class SidebarDrawer extends StatefulWidget {
  const SidebarDrawer({super.key});

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer> {
  String _userName = 'Thrifter';
  int _buyerUnopenedOrders = 0;
  int _sellerUnopenedOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadBadgeCounts();
  }

  void _loadUserProfile() {
    if (UserService.currentUser != null) {
      setState(() {
        _userName = UserService.currentUser!['name'] ?? 'Thrifter';
      });
    }
  }

  Future<void> _loadBadgeCounts() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    try {
      final buyerCount = await OrderService().getUnopenedOrdersCount(
        userId,
        sellerMode: false,
        forceRefresh: true,
      );
      final sellerCount = await OrderService().getUnopenedOrdersCount(
        userId,
        sellerMode: true,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _buyerUnopenedOrders = buyerCount;
        _sellerUnopenedOrders = sellerCount;
      });
    } catch (_) {}
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
                  colors: [Color(0xFFEAF8F6), Color(0xFFDDF4EB)],
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
                    child: UserAvatar(
                      name: _userName,
                      photoPath: UserService.currentUser?['photo_path']
                          ?.toString(),
                      radius: 32,
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
              badgeCount: _buyerUnopenedOrders,
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await navigator.pushNamed('/orders');
                if (mounted) _loadBadgeCounts();
              },
            ),
            _buildMenuItem(
              icon: Icons.storefront_outlined,
              label: 'Penjualan Saya',
              badgeCount: _sellerUnopenedOrders,
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await navigator.pushNamed('/sales');
                if (mounted) _loadBadgeCounts();
              },
            ),
            _buildMenuItem(
              icon: Icons.analytics_outlined,
              label: 'Laporan Penjualan',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sales-report');
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
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
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
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: iconColor ?? AppColors.primary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: badgeCount > 0 ? _buildBadge(badgeCount) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
