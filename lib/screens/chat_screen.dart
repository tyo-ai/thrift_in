import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'checkout_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();


  final List<Map<String, dynamic>> _messages = [
    {'text': 'Halo! Selamat pagi. Ada yang bisa saya bantu dengan Trench Coat-nya?', 'isSeller': true, 'time': '08:13'},
    {'text': 'Halo kak, apakah barangnya masih ada? Dan apakah harganya masih nego sedikit?', 'isSeller': false, 'time': '08:15'},
    {'offer': true, 'amount': 'Rp 420.000', 'time': '08:16'},
    {'text': 'Masih ada kok. Untuk harganya, Rp 420.000 bagaimana? kondisinya sangat baik sekali, baru dipakai 2 kali.', 'isSeller': true, 'time': '08:17'},
  ];

  @override
  void dispose() {
    _msgController.dispose();
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 10, height: 10,
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
                  const Text('Ahmad Thrift Store',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Online', style: TextStyle(fontSize: 11, color: AppColors.success)),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      'https://picsum.photos/seed/trenchcoat/50/50',
                      width: 32, height: 32, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 32, height: 32, color: AppColors.grey100,
                        child: const Icon(Icons.image_outlined, size: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Vintage Beige Trench Coat',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const Text('Rp 450.000', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CheckoutScreen(
                    product: const {
                      'id': 1,
                      'name': 'Vintage Beige Trench Coat',
                      'imageUrl': 'https://picsum.photos/seed/trenchcoat/50/50',
                      'seller_id': 1,
                    },
                    finalPrice: 450000,
                  ))),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Pesan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['offer'] == true) {
                  return _buildOfferCard(msg['amount'], msg['time']);
                }
                return _buildBubble(msg['text'], msg['isSeller'], msg['time']);
              },
            ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: AppColors.textHint),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isSeller, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSeller ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isSeller) ...[
            const CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSeller ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSeller ? AppColors.grey100 : AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSeller ? 4 : 16),
                      bottomRight: Radius.circular(isSeller ? 16 : 4),
                    ),
                  ),
                  child: Text(text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSeller ? AppColors.textPrimary : Colors.white,
                      height: 1.4,
                    )),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
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
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Andi menawarkan penawaran',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(amount, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<Map<String, dynamic>> _chats = const [
    {
      'name': 'Ahmad Thrift Store',
      'lastMsg': 'Masih ada kok, untuk harganya...',
      'time': '08:17',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'unread': 1,
    },
    {
      'name': 'Vintage Corner ID',
      'lastMsg': 'Oke kak, nanti saya proses ya',
      'time': 'Kemarin',
      'avatar': 'https://i.pravatar.cc/150?img=7',
      'unread': 0,
    },
    {
      'name': 'ThriftKing_99',
      'lastMsg': 'Terima kasih sudah belanja!',
      'time': 'Senin',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'unread': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Chat', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(chat['avatar']),
            ),
            title: Text(chat['name'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            subtitle: Text(chat['lastMsg'],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat['time'], style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                if (chat['unread'] > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Text('${chat['unread']}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatScreen())),
          );
        },
      ),
    );
  }
}
