import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar_drawer.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _userName => UserService.currentUser?['name'] ?? 'Andhika';

  List<Map<String, dynamic>> _myItems = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _dummyItems = [
    {
      'name': '90s Vintage Denim Jacket',
      'price': 350000,
      'imageUrl':
          'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=700',
      'badge': 'Like New',
      'isBid': false,
      'liked': true,
    },
    {
      'name': 'Earthy Leather Handbag',
      'price': 890000,
      'imageUrl':
          'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=700',
      'badge': 'Premium',
      'isBid': false,
      'liked': false,
    },
    {
      'name': 'Organic Cotton Tee',
      'price': 120000,
      'imageUrl':
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=700',
      'badge': 'Eco-Friendly',
      'isBid': false,
      'liked': false,
    },
    {
      'name': 'Classic High-top Kicks',
      'price': 450000,
      'imageUrl':
          'https://images.unsplash.com/photo-1600269452121-4f2416e55c28?w=700',
      'badge': 'Good Condition',
      'isBid': false,
      'liked': false,
    },
    {
      'name': 'Minimalist Timepiece',
      'price': 1150000,
      'imageUrl':
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=700',
      'badge': 'Current Bid',
      'isBid': true,
      'liked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (UserService.currentUserId != null) {
        final items = await ProductService().getProductsBySeller(
          UserService.currentUserId!,
        );

        if (!mounted) return;

        setState(() {
          _myItems = items.isEmpty ? _dummyItems : items;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _myItems = _dummyItems;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _myItems = _dummyItems;
        _isLoading = false;
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              UserService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _text(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Rp 0';

    if (value is num) {
      final raw = value.round().toString();
      final formatted = raw.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
      return 'Rp $formatted';
    }

    final text = value.toString();

    if (text.toLowerCase().startsWith('rp')) {
      return text;
    }

    final onlyNumber = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (onlyNumber.isEmpty) return 'Rp 0';

    final formatted = onlyNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 54,
        leadingWidth: 42,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 21,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'ThriftIn',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary,
              size: 21,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 21,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
              size: 21,
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyItemsGrid(_myItems),
                      _buildMyItemsGrid(
                        _myItems.where((item) {
                          return item['isBid'] == 1 || item['isBid'] == true;
                        }).toList(),
                        emptyMessage: 'Belum ada lelang aktif',
                      ),
                      _buildReviews(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF8F6),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFE8EEF4),
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=${_userName.replaceAll(' ', '+')}&background=E7F4F1&color=007F63&bold=true',
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 4,
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _userName,
            style: TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF4EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Verified Thrifter',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'CEO Alibaba alibaba aduh aduh',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStat('1.2K', 'Mengikuti'),
              _buildStat('850', 'Pengikut'),
              _buildStat('142', 'Terjual'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur edit profil belum dibuat.'),
                  ),
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
              ),
              label: const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 54,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.4,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textPrimary,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Jualan Saya'),
          Tab(text: 'Lelang Aktif'),
          Tab(text: 'Ulasan'),
        ],
      ),
    );
  }

  Widget _buildMyItemsGrid(
    List<Map<String, dynamic>> items, {
    String emptyMessage = 'Belum ada produk',
  }) {
    if (items.isEmpty) {
      return _buildPlaceholder(emptyMessage);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: 0.57,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: item),
              ),
            );
          },
          child: _buildProductCard(item),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final isBid = item['isBid'] == 1 || item['isBid'] == true;
    final isLiked = item['liked'] == 1 || item['liked'] == true;
    final imageUrl = _text(item['imageUrl'] ?? item['image'], '');
    final name = _text(item['name'], 'Nama Produk');
    final badge = isBid ? 'Lelang' : _text(item['badge'], 'Like New');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EEF6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildProductImage(imageUrl),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.red : AppColors.textSecondary,
                    size: 17,
                  ),
                ),
              ),
              if (isBid)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB21A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          size: 9,
                          color: Color(0xFF5A3500),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Lelang',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5A3500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatPrice(item['price']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isBid
                          ? const Color(0xFFB96C00)
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isBid
                          ? const Color(0xFFFFF2CF)
                          : const Color(0xFFE7F6EF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: isBid
                            ? const Color(0xFFB96C00)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _buildImagePlaceholder();
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 142,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    return Image.asset(
      imageUrl,
      height: 142,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 142,
      width: double.infinity,
      color: const Color(0xFFEFF3F6),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 34,
      ),
    );
  }

  Widget _buildReviews() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReviewCard(
          name: 'Raka',
          review: 'Barangnya bagus, pengiriman cepat, seller ramah.',
          rating: '5.0',
        ),
        _buildReviewCard(
          name: 'Nadia',
          review: 'Produk sesuai foto dan kondisi masih oke.',
          rating: '4.8',
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String review,
    required String rating,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EEF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEAF8F6),
            child: Text(
              name[0],
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB800),
                size: 15,
              ),
              const SizedBox(width: 2),
              Text(
                rating,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}