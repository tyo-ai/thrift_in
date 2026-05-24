import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_item.dart';
import '../services/db_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final db = await DbHelper().database;
      final results = await db.query('notifications');
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
      final db = await DbHelper().database;
      await db.update('notifications', {'isUnread': 0});
      _loadNotifications();
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
    final unreadNotifs = _notifs.where((n) => n['isUnread'] == 1 || n['isUnread'] == true).toList();
    final readNotifs = _notifs.where((n) => n['isUnread'] == 0 || n['isUnread'] == false).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Title section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Update aktivitas terbaru\nakunmu',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            if (unreadNotifs.isNotEmpty)
                              TextButton(
                                onPressed: _markAllAsRead,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Tandai sudah\ndibaca',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                          ],
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
                            Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.grey300),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...unreadNotifs.map((n) => NotificationItem(
                          icon: _getIconData(n['iconName'] ?? ''),
                          iconBgColor: _getColor(n['iconBgColorHex'] ?? 'FFFFFFFF'),
                          iconColor: _getColor(n['iconColorHex'] ?? 'FF000000'),
                          title: n['title'] ?? '',
                          time: n['time'] ?? '',
                          description: n['description'] ?? '',
                          isUnread: true,
                        )),
                    const SizedBox(height: 16),
                  ],

                  // SEBELUMNYA section
                  if (readNotifs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'SEBELUMNYA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...readNotifs.map((n) => NotificationItem(
                          icon: _getIconData(n['iconName'] ?? ''),
                          iconBgColor: _getColor(n['iconBgColorHex'] ?? 'FFFFFFFF'),
                          iconColor: _getColor(n['iconColorHex'] ?? 'FF000000'),
                          title: n['title'] ?? '',
                          time: n['time'] ?? '',
                          description: n['description'] ?? '',
                          isUnread: false,
                        )),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }
}
