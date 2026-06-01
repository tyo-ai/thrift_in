import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_item.dart';
import '../widgets/skeleton_loaders.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    try {
      final results = await _notificationService.getNotifications(
        forceRefresh: forceRefresh,
      );
      setState(() {
        _notifs = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _loadNotifications(forceRefresh: true);
    } catch (e) {
      // ignore
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'gavel':
        return Icons.gavel_rounded;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'handshake':
        return Icons.handshake_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'emoji_events':
        return Icons.emoji_events_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColor(String hex) {
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = _notifs
        .where((n) => n['isUnread'] == 1 || n['isUnread'] == true)
        .toList();
    final readNotifs = _notifs
        .where((n) => n['isUnread'] == 0 || n['isUnread'] == false)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FB),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thriftin',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? SkeletonLoaders.notificationList()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notifikasi',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  unreadNotifs.isEmpty
                                      ? 'Semua aktivitas sudah dibaca'
                                      : '${unreadNotifs.length} update baru menunggumu',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unreadNotifs.isNotEmpty)
                            TextButton(
                              onPressed: _markAllAsRead,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'Baca semua',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Aktivitas akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE2EAF2)),
                          ),
                          child: Text(
                            '${_notifs.length} total',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_notifs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: AppColors.grey300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada notifikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // TERBARU section
                  if (unreadNotifs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'TERBARU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...unreadNotifs.map(
                      (n) => NotificationItem(
                        icon: _getIconData(n['iconName'] ?? ''),
                        iconBgColor: _getColor(
                          n['iconBgColorHex'] ?? 'FFFFFFFF',
                        ),
                        iconColor: _getColor(n['iconColorHex'] ?? 'FF000000'),
                        title: n['title'] ?? '',
                        time: n['time'] ?? '',
                        description: n['description'] ?? '',
                        isUnread: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SEBELUMNYA section
                  if (readNotifs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'SEBELUMNYA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textHint,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...readNotifs.map(
                      (n) => NotificationItem(
                        icon: _getIconData(n['iconName'] ?? ''),
                        iconBgColor: _getColor(
                          n['iconBgColorHex'] ?? 'FFFFFFFF',
                        ),
                        iconColor: _getColor(n['iconColorHex'] ?? 'FF000000'),
                        title: n['title'] ?? '',
                        time: n['time'] ?? '',
                        description: n['description'] ?? '',
                        isUnread: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }
}
