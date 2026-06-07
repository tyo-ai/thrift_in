import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/supabase_config.dart';
import '../services/user_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    try {
      final userId = UserService.currentUserId;
      if (userId == null) {
        setState(() {
          _paymentMethods = [];
          _isLoading = false;
        });
        return;
      }

      final results = await SupabaseConfig.client
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('id', ascending: false);
      setState(() {
        _paymentMethods = results
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultMethod(int methodId) async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) return;

      await SupabaseConfig.client
          .from('payment_methods')
          .update({'is_default': 0})
          .eq('user_id', userId);
      await SupabaseConfig.client
          .from('payment_methods')
          .update({'is_default': 1})
          .eq('user_id', userId)
          .eq('id', methodId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rekening utama berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui rekening utama: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteMethod(int methodId) async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) return;

      await SupabaseConfig.client
          .from('payment_methods')
          .delete()
          .eq('user_id', userId)
          .eq('id', methodId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rekening penjual telah dihapus'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addPaymentMethod(
    String name,
    String type,
    String accountNumber,
    bool makeDefault,
  ) async {
    try {
      final userId = UserService.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      int isDefaultValue = makeDefault ? 1 : 0;

      if (makeDefault) {
        await SupabaseConfig.client
            .from('payment_methods')
            .update({'is_default': 0})
            .eq('user_id', userId);
      }
      await SupabaseConfig.client.from('payment_methods').insert({
        'user_id': userId,
        'type': type,
        'name': name,
        'account_number': accountNumber,
        'is_default': isDefaultValue,
        'image_url': '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rekening penjual berhasil ditambahkan!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan ke database: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          'Rekening Penjual',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: _paymentMethods.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _paymentMethods.length,
                          itemBuilder: (context, index) {
                            final method = _paymentMethods[index];
                            return _buildPaymentCard(method);
                          },
                        ),
                ),
                _buildAddButton(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(
              'Belum ada rekening penjual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan rekening bank atau e-wallet untuk pencairan dana penjualan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> method) {
    final name = method['name'] as String;
    final type = method['type'] as String;
    final number = method['account_number'] as String;
    final isDefault =
        (method['is_default'] == 1 || method['is_default'] == true);

    // Branded card styling
    Color cardColor;
    Color textOnCardColor = Colors.white;
    List<Color> gradients;

    if (name.toLowerCase().contains('gopay')) {
      cardColor = const Color(0xFF00B0FF); // GoPay Cyan
      gradients = [const Color(0xFF0091EA), const Color(0xFF00B0FF)];
    } else if (name.toLowerCase().contains('dana')) {
      cardColor = const Color(0xFF1976D2); // DANA Blue
      gradients = [const Color(0xFF0D47A1), const Color(0xFF1976D2)];
    } else if (name.toLowerCase().contains('bca')) {
      cardColor = const Color(0xFF0D47A1); // BCA dark blue
      gradients = [const Color(0xFF0A2540), const Color(0xFF1A365D)];
    } else {
      cardColor = AppColors.primary;
      gradients = [AppColors.primaryDark, AppColors.primary];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentOptions(method),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Type / default badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: textOnCardColor.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 10),
                            SizedBox(width: 4),
                            Text(
                              'Utama',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Center row: Bank / Wallet Name
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textOnCardColor,
                    letterSpacing: -0.5,
                  ),
                ),

                // Bottom row: Account Number / action icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w600,
                        color: textOnCardColor.withValues(alpha: 0.85),
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(Icons.more_horiz, color: textOnCardColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _showAddPaymentBottomSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Rekening Penjual',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions(Map<String, dynamic> method) {
    final id = method['id'] as int;
    final name = method['name'] as String;
    final isDefault =
        (method['is_default'] == 1 || method['is_default'] == true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (!isDefault)
                ListTile(
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Atur sebagai Rekening Utama',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _setDefaultMethod(id);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Hapus Rekening Penjual',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(id);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rekening'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus rekening penjual ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMethod(id);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    String selectedType = 'Bank';
    bool makeDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tambah Rekening Penjual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selection of Type
                    Text(
                      'Tipe Akun',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Bank', 'E-Wallet'].map((type) {
                        final isSelected = selectedType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedType = type),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                type,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Brand Name Input
                    Text(
                      'Nama Bank / E-Wallet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: selectedType == 'E-Wallet'
                            ? 'Misal: GoPay, DANA'
                            : 'Misal: BCA, Mandiri, BNI',
                        filled: true,
                        fillColor: AppColors.grey50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Account Number Input
                    Text(
                      selectedType == 'E-Wallet'
                          ? 'Nomor HP E-Wallet'
                          : 'Nomor Rekening',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: selectedType == 'E-Wallet'
                            ? '0812XXXXXXXX'
                            : '1234567890',
                        filled: true,
                        fillColor: AppColors.grey50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nomor tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Default Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Jadikan rekening utama',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: makeDefault,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setModalState(() => makeDefault = v),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            _addPaymentMethod(
                              nameController.text.trim(),
                              selectedType,
                              numberController.text.trim(),
                              makeDefault,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan Rekening',
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
            );
          },
        );
      },
    );
  }
}
