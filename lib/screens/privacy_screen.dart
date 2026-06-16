import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Kebijakan Privasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kebijakan Privasi Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kami di Thriftin sangat menghargai privasi Anda. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda:\n\n'
              '1. Pengumpulan Informasi\n'
              'Kami mengumpulkan informasi yang Anda berikan saat mendaftar, seperti nama, email, nomor telepon, dan alamat pengiriman.\n\n'
              '2. Penggunaan Informasi\n'
              'Informasi Anda digunakan untuk memproses pesanan, meningkatkan pengalaman pengguna, dan memberikan dukungan pelanggan. Kami tidak menjual data pribadi Anda kepada pihak ketiga.\n\n'
              '3. Keamanan Data\n'
              'Kami menerapkan berbagai langkah keamanan untuk menjaga keamanan informasi pribadi Anda. Namun, tidak ada metode transmisi melalui internet yang 100% aman.\n\n'
              '4. Hak Pengguna\n'
              'Anda berhak untuk mengakses, memperbaiki, atau meminta penghapusan data pribadi Anda melalui layanan pelanggan kami.\n\n'
              '5. Hubungi Kami\n'
              'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini, silakan hubungi layanan pelanggan kami.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
