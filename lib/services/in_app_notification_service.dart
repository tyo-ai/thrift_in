import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_colors.dart';
import '../screens/chat_screen.dart';
import '../main.dart';

class InAppNotificationService {
  static OverlayEntry? _currentOverlay;

  static void show({
    required Map<String, dynamic> room,
    required String senderName,
    required String message,
  }) {
    final state = ThriftinApp.navigatorKey.currentState;
    if (state == null) return;

    // Remove any currently showing notification
    dismiss();

    final overlayState = state.overlay;
    if (overlayState == null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) {
        return _InAppNotificationBanner(
          room: room,
          senderName: senderName,
          message: message,
          onDismiss: dismiss,
        );
      },
    );

    overlayState.insert(_currentOverlay!);
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _InAppNotificationBanner extends StatefulWidget {
  final Map<String, dynamic> room;
  final String senderName;
  final String message;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.room,
    required this.senderName,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      _dismissWithAnimation();
    });
  }

  Future<void> _dismissWithAnimation() async {
    _autoDismissTimer?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top : 16.0;

    final otherUser = widget.room['buyer_id'] == widget.room['buyer']?['id']
        ? widget.room['seller']
        : widget.room['buyer'];
    final photoPath = otherUser?['photo_path']?.toString() ?? widget.room['seller']?['photo_path']?.toString() ?? widget.room['buyer']?['photo_path']?.toString();

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Dismissible(
          key: const Key('in_app_chat_notif'),
          direction: DismissDirection.up,
          onDismissed: (_) {
            _autoDismissTimer?.cancel();
            widget.onDismiss();
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _dismissWithAnimation();
                ThriftinApp.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(room: widget.room),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EDF5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: widget.senderName,
                      photoPath: photoPath,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.senderName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Pesan Baru',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                      onPressed: _dismissWithAnimation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
