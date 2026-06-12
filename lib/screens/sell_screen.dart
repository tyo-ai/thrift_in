import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'package:image_cropper/image_cropper.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  int _selectedCondition = -1; // 0=Minus, 1=Sedikit Minus, 2=Banyak Minus
  int _selectedMethod = 0; // 0=Harga Tetap, 1=Lelang
  int _selectedAuctionDuration = 2;
  bool _ekspedisi = true;
  bool _instant = false;
  bool _cod = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  final List<String?> _imagePaths = List.filled(5, null, growable: false);

  final List<String> _categories = [
    'Pakaian',
    'Sepatu',
    'Tas',
    'Aksesoris',
    'Elektronik',
    'Buku',
    'Furnitur',
  ];

  final List<Map<String, dynamic>> _auctionDurations = const [
    {'label': '6 Jam', 'duration': Duration(hours: 6)},
    {'label': '12 Jam', 'duration': Duration(hours: 12)},
    {'label': '1 Hari', 'duration': Duration(days: 1)},
    {'label': '3 Hari', 'duration': Duration(days: 3)},
    {'label': '7 Hari', 'duration': Duration(days: 7)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'Jual Barang',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Upload Section
            _buildSectionLabel('Foto Barang (Maks. 5)'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    // Main photo slot
                    GestureDetector(
                      onTap: () => _pickImage(0),
                      child: _buildPhotoSlot(
                        isMain: true,
                        imagePath: _imagePaths[0],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Secondary slots
                    ...List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _pickImage(i + 1),
                          child: _buildPhotoSlot(imagePath: _imagePaths[i + 1]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tips: Tambahkan foto dari berbagai sudut untuk menarik pembeli',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // Judul Barang
            _buildSectionLabel('Judul Barang'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Contoh: Jaket Vintage Levi\'s 503 Original',
              ),
            ),
            const SizedBox(height: 16),

            // Kategori
            _buildSectionLabel('Kategori'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              hint: const Text(
                'Pilih Kategori',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
              decoration: _inputDecoration(''),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              dropdownColor: AppColors.background,
            ),
            const SizedBox(height: 16),

            // Kondisi
            _buildSectionLabel('Kondisi'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildConditionChip('Minus', 0),
                const SizedBox(width: 8),
                _buildConditionChip('Sedikit Minus', 1),
                const SizedBox(width: 8),
                _buildConditionChip('Banyak Minus', 2),
              ],
            ),
            const SizedBox(height: 16),

            // Metode Penjualan
            _buildSectionLabel('Metode Penjualan'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildMethodTab('Harga Tetap', 0),
                  _buildMethodTab('Lelang', 1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration(
                    _selectedMethod == 1 ? 'Harga awal' : ' 0',
                  ).copyWith(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                  ),
            ),
            if (_selectedMethod == 1) ...[
              const SizedBox(height: 16),
              _buildSectionLabel('Durasi Lelang'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _auctionDurations.length,
                  (index) => _buildAuctionDurationChip(index),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Berakhir ${_auctionEndPreview()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),

            _buildSectionLabel('Lokasi / Alamat Barang'),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: _inputDecoration(
                'Contoh: Lowokwaru, Malang atau alamat toko',
              ),
            ),
            const SizedBox(height: 20),

            // Deskripsi Barang
            _buildSectionLabel('Deskripsi Barang'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: _inputDecoration(
                'Ceritakan detail barang, ukuran, material, atau alasan dijual...',
              ),
            ),
            const SizedBox(height: 20),

            // Metode Pengiriman
            _buildSectionLabel('Metode Pengiriman'),
            const SizedBox(height: 8),
            _buildShippingOption(
              icon: Icons.local_shipping_outlined,
              title: 'Ekspedisi Regular',
              subtitle: '2–5 hari kerja',
              value: _ekspedisi,
              onChanged: (v) => setState(() => _ekspedisi = v!),
            ),
            const SizedBox(height: 8),
            _buildShippingOption(
              icon: Icons.flash_on_outlined,
              title: 'Instant / Sameday',
              subtitle: 'Hari yang sama',
              value: _instant,
              onChanged: (v) => setState(() => _instant = v!),
            ),
            const SizedBox(height: 8),
            _buildShippingOption(
              icon: Icons.handshake_outlined,
              title: 'COD (Ketemuan)',
              subtitle: 'Titik temu kesepakatan',
              value: _cod,
              onChanged: (v) => setState(() => _cod = v!),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          final title = _titleController.text.trim();
                          final priceVal = _priceController.text.trim();
                          final location = _locationController.text.trim();

                          if (title.isEmpty ||
                              priceVal.isEmpty ||
                              location.isEmpty) {
                            _showAppSnackBar(
                              'Judul, harga, dan lokasi harus diisi',
                              isError: true,
                            );
                            return;
                          }

                          if (_imagePaths[0] == null) {
                            _showAppSnackBar(
                              'Harap tambahkan foto barang utama',
                              isError: true,
                            );
                            return;
                          }

                          // Format price as 'Rp X.XXX.XXX' if it's entered as raw number
                          String formattedPrice = priceVal;
                          if (!priceVal.startsWith('Rp')) {
                            final numPrice = int.tryParse(
                              priceVal.replaceAll(RegExp(r'[^0-9]'), ''),
                            );
                            if (numPrice != null) {
                              final reg = RegExp(
                                r'(\d{1,3})(?=(\d{3})+(?!\d))',
                              );
                              formattedPrice =
                                  'Rp ${numPrice.toString().replaceAllMapped(reg, (Match m) => '${m[1]}.')}';
                            } else {
                              formattedPrice = 'Rp $priceVal';
                            }
                          }

                          // Determine badge name based on condition: 0=Minus, 1=Sedikit Minus, 2=Banyak Minus
                          String? badge;
                          if (_selectedCondition == 0) badge = 'Minus';
                          if (_selectedCondition == 1) badge = 'Bagus';
                          if (_selectedCondition == 2) badge = 'Sangat Bagus';

                          final sellerId = UserService.currentUserId ?? 1;
                          final endTime = _selectedMethod == 1
                              ? DateTime.now()
                                    .add(
                                      _auctionDurations[_selectedAuctionDuration]['duration']
                                          as Duration,
                                    )
                                    .toIso8601String()
                              : null;

                          final navigator = Navigator.of(context);
                          List<String> uploadedImageUrls;
                          try {
                            uploadedImageUrls = [];
                            for (var i = 0; i < _imagePaths.length; i++) {
                              final path = _imagePaths[i];
                              if (path == null) continue;
                              final url = await ProductService()
                                  .uploadProductImage(
                                    imageFile: File(path),
                                    sellerId: sellerId,
                                    index: i,
                                  );
                              uploadedImageUrls.add(url);
                            }
                          } catch (e) {
                            if (!mounted) return;
                            _showAppSnackBar(
                              'Gagal mengupload foto produk: $e',
                              isError: true,
                            );
                            return;
                          }

                          if (uploadedImageUrls.isEmpty) {
                            _showAppSnackBar(
                              'Harap tambahkan foto barang utama',
                              isError: true,
                            );
                            return;
                          }

                          // Get current logged-in user name as store name
                          final storeName =
                              UserService.currentUser?['name'] ?? 'Toko Saya';

                          // Call product service to save
                          final newId = await ProductService().addProduct(
                            sellerId: sellerId,
                            name: title,
                            price: formattedPrice,
                            rating: 0.0,
                            reviewCount: 0,
                            category: _selectedCategory ?? 'Semua',
                            storeName: storeName,
                            location: location,
                            imageUrl: uploadedImageUrls.first,
                            badge: badge,
                            isBid: _selectedMethod == 1,
                            endTime: endTime,
                            description: _descController.text.trim(),
                            imageUrls: uploadedImageUrls,
                          );

                          if (newId > 0) {
                            if (!mounted) return;
                            _showAppSnackBar(
                              _selectedMethod == 1
                                  ? 'Produk lelang berhasil dipasang'
                                  : 'Iklan berhasil dipasang',
                              icon: _selectedMethod == 1
                                  ? Icons.gavel_rounded
                                  : Icons.storefront_rounded,
                            );

                            await Future.delayed(
                              const Duration(milliseconds: 900),
                            );
                            if (!mounted) return;

                            // Clear inputs
                            _titleController.clear();
                            _priceController.clear();
                            _descController.clear();
                            _locationController.clear();
                            setState(() {
                              _selectedCategory = null;
                              _selectedCondition = -1;
                              _selectedMethod = 0;
                              _selectedAuctionDuration = 2;
                              _ekspedisi = true;
                              _instant = false;
                              _cod = false;
                              _imagePaths.fillRange(0, 5, null);
                            });

                            navigator.pushNamedAndRemoveUntil(
                              '/home',
                              (route) => false,
                            );
                          } else {
                            _showAppSnackBar(
                              'Gagal memasang iklan',
                              isError: true,
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Mengupload...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pasang Iklan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Foto Produk',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              activeControlsWidgetColor: AppColors.primary,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ],
            ),
            IOSUiSettings(
              title: 'Crop Foto Produk',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imagePaths[index] = croppedFile.path;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showAppSnackBar('Gagal memilih atau crop gambar', isError: true);
    }
  }

  void _showAppSnackBar(
    String message, {
    bool isError = false,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({bool isMain = false, String? imagePath}) {
    return Container(
      width: isMain ? 100 : 70,
      height: isMain ? 100 : 70,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      clipBehavior: Clip.hardEdge,
      child: imagePath != null
          ? Image.file(File(imagePath), fit: BoxFit.cover)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: isMain ? 28 : 20,
                  color: AppColors.textHint,
                ),
                if (isMain) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Utama',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildConditionChip(String label, int index) {
    final selected = _selectedCondition == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCondition = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String label, int index) {
    final selected = _selectedMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuctionDurationChip(int index) {
    final selected = _selectedAuctionDuration == index;
    final label = _auctionDurations[index]['label'] as String;

    return GestureDetector(
      onTap: () => setState(() => _selectedAuctionDuration = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _auctionEndPreview() {
    final duration =
        _auctionDurations[_selectedAuctionDuration]['duration'] as Duration;
    final endTime = DateTime.now().add(duration);
    final day = endTime.day.toString().padLeft(2, '0');
    final month = endTime.month.toString().padLeft(2, '0');
    final hour = endTime.hour.toString().padLeft(2, '0');
    final minute = endTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  Widget _buildShippingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: value ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ],
      ),
    );
  }
}
