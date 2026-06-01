import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_config.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Masalah Pembayaran';

  String _faqSearchQuery = '';
  List<Map<String, dynamic>> _inquiryHistory = [];
  bool _isLoadingHistory = true;

  final List<Map<String, dynamic>> _faqData = [
    {
      'category': 'Lelang (Bidding)',
      'questions': [
        {
          'q': 'Bagaimana cara melakukan penawaran (bid)?',
          'a':
              'Pilih produk lelang yang Anda inginkan, masukkan jumlah penawaran Anda di atas harga saat ini, lalu tekan tombol "Tawar". Pastikan saldo e-wallet Anda mencukupi atau bersiap melakukan pembayaran ketika waktu lelang berakhir.',
        },
        {
          'q': 'Apakah penawaran yang sudah diajukan bisa dibatalkan?',
          'a':
              'Demi menjaga keadilan dan komitmen, penawaran lelang yang sudah diajukan tidak dapat dibatalkan. Mohon lakukan bid dengan bijak.',
        },
        {
          'q': 'Bagaimana jika saya memenangkan lelang?',
          'a':
              'Anda akan menerima notifikasi kemenangan lelang. Anda memiliki waktu 24 jam untuk menyelesaikan pembayaran produk lelang tersebut melalui menu pembayaran.',
        },
      ],
    },
    {
      'category': 'Pembayaran & Keamanan',
      'questions': [
        {
          'q': 'Metode pembayaran apa saja yang didukung?',
          'a':
              'Kami mendukung berbagai metode pembayaran aman termasuk e-wallet (GoPay, DANA, ShopeePay), Virtual Account Bank (BCA, Mandiri, BNI), serta kartu debit dan kredit.',
        },
        {
          'q': 'Apakah transaksi di Thriftin aman?',
          'a':
              'Tentu saja! Kami menggunakan sistem Rekening Bersama (Escrow). Dana Anda akan kami tahan dengan aman dan hanya dilepaskan ke penjual setelah Anda mengonfirmasi barang diterima dengan baik.',
        },
      ],
    },
    {
      'category': 'Pengiriman',
      'questions': [
        {
          'q': 'Berapa lama estimasi pengiriman barang?',
          'a':
              'Estimasi pengiriman tergantung pada jenis kurir yang Anda pilih saat checkout dan lokasi penjual. Biasanya memakan waktu 2-5 hari kerja.',
        },
        {
          'q': 'Bagaimana cara melacak pesanan saya?',
          'a':
              'Masuk ke halaman "Pesanan Saya", pilih detail pesanan yang ingin Anda lacak, lalu klik tombol "Lacak" untuk melihat status pengiriman kurir secara real-time.',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInquiryHistory();
  }

  Future<void> _loadInquiryHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final results = await SupabaseConfig.client
          .from('help_messages')
          .select()
          .order('id', ascending: false);
      setState(() {
        _inquiryHistory = results
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    try {
      final result = await SupabaseConfig.client
          .from('help_messages')
          .insert({
            'name': name,
            'email': email,
            'category': _selectedCategory,
            'message': message,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      if (!mounted) return;

      // Clear controllers
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();

      _showSuccessDialog(result['id'] as int);
      _loadInquiryHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(int ticketId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Laporan Terkirim!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiket Anda berhasil dibuat dengan ID:\n#TKT-${1000 + ticketId}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tim Customer Support kami akan segera menghubungi Anda melalui email dalam waktu maksimal 24 jam.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFAQs() {
    if (_faqSearchQuery.trim().isEmpty) return _faqData;

    List<Map<String, dynamic>> filtered = [];

    for (var cat in _faqData) {
      final questions = cat['questions'] as List<Map<String, String>>;
      final matchedQuestions = questions.where((q) {
        return q['q']!.toLowerCase().contains(_faqSearchQuery.toLowerCase()) ||
            q['a']!.toLowerCase().contains(_faqSearchQuery.toLowerCase());
      }).toList();

      if (matchedQuestions.isNotEmpty) {
        filtered.add({
          'category': cat['category'],
          'questions': matchedQuestions,
        });
      }
    }
    return filtered;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
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
          'Pusat Bantuan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'FAQ / Tanya Jawab'),
                Tab(text: 'Hubungi Kami'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFAQTab(), _buildContactTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final filteredFAQ = _getFilteredFAQs();
    return Column(
      children: [
        // Search bar
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: TextFormField(
            onChanged: (val) => setState(() => _faqSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari masalah Anda...',
              prefixIcon: Icon(Icons.search, color: AppColors.grey400),
              filled: true,
              fillColor: AppColors.grey100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredFAQ.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'FAQ tidak ditemukan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredFAQ.length,
                  itemBuilder: (context, index) {
                    final cat = filteredFAQ[index];
                    final categoryName = cat['category'] as String;
                    final questions = cat['questions'] as List;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Text(
                            categoryName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...questions.map((q) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                q['q']!,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              shape: Border.all(color: Colors.transparent),
                              collapsedShape: Border.all(
                                color: Colors.transparent,
                              ),
                              backgroundColor: Colors.transparent,
                              collapsedBackgroundColor: Colors.transparent,
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                Text(
                                  q['a']!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    final categories = [
      'Masalah Lelang',
      'Masalah Pembayaran',
      'Akun & Keamanan',
      'Lainnya',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card promo
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, const Color(0xFF14663F)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Punya Pertanyaan Lain?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tuliskan detail masalah Anda di bawah ini, tim support kami siap melayani Anda sepenuh hati.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.headset_mic_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama Anda...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),

                // Email
                Text(
                  'Alamat Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                Text(
                  'Kategori Masalah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.background,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description message
                Text(
                  'Deskripsi Masalah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Jelaskan secara rinci kendala yang Anda alami...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Harap jelaskan masalah minimal 10 karakter'
                      : null,
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitInquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kirim Laporan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Inquiry History List (High-fidelity SQL integration display)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Laporan Anda',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_inquiryHistory.isNotEmpty)
                GestureDetector(
                  onTap: _loadInquiryHistory,
                  child: Icon(
                    Icons.refresh,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingHistory
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _inquiryHistory.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Belum ada laporan kendala yang dikirim.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _inquiryHistory.length,
                  itemBuilder: (context, index) {
                    final item = _inquiryHistory[index];
                    final id = item['id'] as int;
                    final category = item['category'] as String;
                    final message = item['message'] as String;
                    final date = item['created_at'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Text(
                                '#TKT-${1000 + id}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date.split('T')[0],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Text(
                                'Menunggu Respon',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
