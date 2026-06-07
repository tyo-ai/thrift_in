import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/cached_product_image.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/user_avatar.dart';
import 'checkout_screen.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? room;
  final Map<String, dynamic>? product;

  static int? activeRoomId;

  const ChatScreen({super.key, this.room, this.product});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  Map<String, dynamic>? _room;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  Map<String, dynamic> get _product {
    final roomProduct = _room?['products'];
    if (roomProduct is Map && roomProduct.isNotEmpty) {
      return Map<String, dynamic>.from(roomProduct);
    }
    return widget.product ?? const {};
  }

  Map<String, dynamic> get _otherUser {
    final currentUserId = UserService.currentUserId;
    final room = _room;
    final isBuyer = room?['buyer_id'] == currentUserId;
    final user = room == null
        ? null
        : (isBuyer ? room['seller'] : room['buyer']);
    if (user is Map && user.isNotEmpty) {
      return Map<String, dynamic>.from(user);
    }
    return const {};
  }

  String get _otherUserName {
    final name = _otherUser['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return _product['storeName']?.toString() ?? 'User Thriftin';
  }

  String? get _otherUserPhoto => _otherUser['photo_path']?.toString().trim();

  @override
  void initState() {
    super.initState();
    _prepareRoom();
  }

  Future<void> _prepareRoom() async {
    try {
      final currentUserId = UserService.currentUserId;
      if (currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (widget.room != null) {
        _room = widget.room;
      } else if (widget.product != null) {
        final sellerId = int.tryParse(
          widget.product?['seller_id']?.toString() ?? '',
        );
        final productId = int.tryParse(widget.product?['id']?.toString() ?? '');
        if (sellerId != null && productId != null) {
          _room = await _chatService.getOrCreateRoom(
            productId: productId,
            buyerId: currentUserId,
            sellerId: sellerId,
          );
        }
      }

      final roomId = int.tryParse(_room?['id']?.toString() ?? '');
      if (roomId != null) {
        ChatScreen.activeRoomId = roomId;
        await _chatService.markRoomAsRead(
          roomId: roomId,
          userId: currentUserId,
        );
      }

      await _loadMessages();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    final roomId = int.tryParse(_room?['id']?.toString() ?? '');
    if (roomId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final messages = await _chatService.getMessages(roomId);
    messages.sort(_compareMessagesByTime);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _msgController.text.trim();
    final roomId = int.tryParse(_room?['id']?.toString() ?? '');
    final senderId = UserService.currentUserId;
    if (message.isEmpty || roomId == null || senderId == null) return;

    _msgController.clear();
    await _chatService.sendMessage(
      roomId: roomId,
      senderId: senderId,
      message: message,
    );
    await _loadMessages();
  }

  @override
  void dispose() {
    final roomId = int.tryParse(_room?['id']?.toString() ?? '');
    if (roomId != null && ChatScreen.activeRoomId == roomId) {
      ChatScreen.activeRoomId = null;
    }
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  int _compareMessagesByTime(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '');
    final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '');
    if (aTime != null && bTime != null) {
      final result = aTime.compareTo(bTime);
      if (result != 0) return result;
    }

    final aId = int.tryParse(a['id']?.toString() ?? '') ?? 0;
    final bId = int.tryParse(b['id']?.toString() ?? '') ?? 0;
    return aId.compareTo(bId);
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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                UserAvatar(
                  name: _otherUserName,
                  photoPath: _otherUserPhoto,
                  radius: 18,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUserName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(fontSize: 11, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Product preview thumbnail
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CachedProductImage(
                    imageUrl:
                        _product['imageUrl']?.toString() ??
                        'https://picsum.photos/seed/trenchcoat/50/50',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(6),
                    memCacheWidth: 96,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _product['name']?.toString() ?? 'Produk Thriftin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _product['price']?.toString() ?? 'Rp 0',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutScreen(
                    product: _product,
                    finalPrice: _parsePrice(_product['price']),
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Pesan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada pesan',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMine =
                           msg['sender_id'] == UserService.currentUserId;
                      final offerAmount = msg['offer_amount'];
                      if (offerAmount != null) {
                        return _buildOfferCard(
                          _formatPrice(offerAmount),
                          _formatTime(msg['created_at']),
                        );
                      }
                      return _buildBubble(
                        msg['message']?.toString() ?? '',
                        !isMine,
                        _formatTime(msg['created_at']),
                      );
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textHint,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _parsePrice(dynamic value) {
    final raw = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(raw) ?? 0;
  }

  String _formatPrice(dynamic value) {
    final price = value is int ? value : _parsePrice(value);
    final formatted = price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  String _formatTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBubble(String text, bool isSeller, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSeller
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isSeller) ...[
            UserAvatar(
              name: _otherUserName,
              photoPath: _otherUserPhoto,
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSeller
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSeller ? AppColors.grey100 : AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSeller ? 4 : 16),
                      bottomRight: Radius.circular(isSeller ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSeller ? AppColors.textPrimary : Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(String amount, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_otherUserName menawarkan penawaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Ubah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inbox List Screen ────────────────────────────────────────────────────────
class ChatListScreen extends StatefulWidget {
  final VoidCallback? onUnreadChanged;

  const ChatListScreen({super.key, this.onUnreadChanged});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isEditing = false;
  final Set<int> _selectedChats = {};
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats({bool forceRefresh = false}) async {
    final userId = UserService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final chats = await _chatService.getRoomsForUser(
        userId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
      widget.onUnreadChanged?.call();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _selectedChats.clear();
    });
  }

  void _deleteSelectedChats() {
    final sortedSelections = _selectedChats.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final index in sortedSelections) {
      final roomId = int.tryParse(_chats[index]['id']?.toString() ?? '');
      if (roomId != null) {
        _chatService.deleteRoom(roomId);
      }
    }
    setState(() {
      for (final index in sortedSelections) {
        _chats.removeAt(index);
      }
      _isEditing = false;
      _selectedChats.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? '${_selectedChats.length} Terpilih' : 'Chat',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _selectedChats.isEmpty ? null : _deleteSelectedChats,
            ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              color: AppColors.primary,
            ),
            onPressed: _toggleEditMode,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? SkeletonLoaders.list(imageSize: 52)
          : _chats.isEmpty
          ? const Center(
              child: Text(
                'Belum ada chat',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              itemCount: _chats.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final isSelected = _selectedChats.contains(index);
                final product = Map<String, dynamic>.from(
                  (chat['products'] as Map?) ?? {},
                );
                final isBuyer = chat['buyer_id'] == UserService.currentUserId;
                final otherUser = Map<String, dynamic>.from(
                  ((isBuyer ? chat['seller'] : chat['buyer']) as Map?) ?? {},
                );
                final title =
                    otherUser['name']?.toString() ??
                    product['storeName']?.toString() ??
                    'Seller Thriftin';
                final unreadCount =
                    int.tryParse(chat['unread']?.toString() ?? '') ?? 0;
                final hasUnread = unreadCount > 0;

                return ListTile(
                  tileColor: hasUnread
                      ? AppColors.primary.withValues(alpha: 0.035)
                      : null,
                  contentPadding: EdgeInsets.only(
                    left: _isEditing ? 8 : 16,
                    right: 16,
                    top: 8,
                    bottom: 8,
                  ),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isEditing)
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedChats.add(index);
                              } else {
                                _selectedChats.remove(index);
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      UserAvatar(
                        name: title,
                        photoPath: otherUser['photo_path']?.toString(),
                        radius: 26,
                      ),
                    ],
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.w900 : FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    chat['last_message']?.toString() ??
                        product['name']?.toString() ??
                        'Mulai percakapan',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatRoomTime(
                          chat['last_message_at'] ?? chat['created_at'],
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: _isEditing
                      ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedChats.remove(index);
                            } else {
                              _selectedChats.add(index);
                            }
                          });
                        }
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(room: chat),
                          ),
                        ).then((_) => _loadChats(forceRefresh: true)),
                );
              },
            ),
    );
  }

  String _formatRoomTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
