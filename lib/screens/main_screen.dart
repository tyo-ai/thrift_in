import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/chat_notification_service.dart';
import '../services/system_notification_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'sell_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _chatRefreshVersion = 0;
  int _chatUnreadCount = 0;
  int _orderUnreadCount = 0;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);
    _pages[0] = const HomeScreen();
    ChatNotificationService.instance.startForCurrentUser(
      onNewMessage: _onNewChatMessage,
    );
    SystemNotificationService.instance.startForCurrentUser();
    _loadBadgeCounts();
  }

  void _onNewChatMessage() {
    _loadBadgeCounts();
  }

  @override
  void dispose() {
    ChatNotificationService.instance.stop();
    SystemNotificationService.instance.stop();
    super.dispose();
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SearchScreen();
      case 3:
        return ChatListScreen(
          key: ValueKey(_chatRefreshVersion),
          onUnreadChanged: _loadBadgeCounts,
        );
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  void _selectTab(int index) {
    if (index == 3) {
      _chatRefreshVersion += 1;
      _pages[index] = _buildPage(index);
      _loadBadgeCounts();
    } else if (index == 4) {
      _loadBadgeCounts();
      if (_pages[index] == null) {
        _pages[index] = _buildPage(index);
      }
    } else if (_pages[index] == null) {
      _pages[index] = _buildPage(index);
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _loadBadgeCounts() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    try {
      final chatUnread = await ChatService().getTotalUnreadCount(userId);
      final orderUnread = await OrderService().getTotalUnopenedOrdersCount(
        userId,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _chatUnreadCount = chatUnread;
        _orderUnreadCount = orderUnread;
      });
    } catch (_) {
      // Badge counts are helpful hints; keep navigation usable if loading fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages
            .map((page) => page ?? const SizedBox.shrink())
            .toList(growable: false),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  outlinedIcon: Icons.home_outlined,
                  label: 'Beranda',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search_rounded,
                  outlinedIcon: Icons.search,
                  label: 'Cari',
                  index: 1,
                ),
                _buildCenterButton(),
                _buildNavItem(
                  icon: Icons.chat_bubble_rounded,
                  outlinedIcon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  index: 3,
                  badgeCount: _chatUnreadCount,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  outlinedIcon: Icons.person_outline,
                  label: 'Profil',
                  index: 4,
                  badgeCount: _orderUnreadCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData outlinedIcon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? icon : outlinedIcon,
                  size: 26,
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: _buildBadge(badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SellScreen()),
        );
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: Colors.white),
            Text(
              'Jual',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
