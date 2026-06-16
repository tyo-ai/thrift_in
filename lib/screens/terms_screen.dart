import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Syarat & Ketentuan',
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
              'Syarat dan Ketentuan Layanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selamat datang di aplikasi Thriftin. Dengan mengakses atau menggunakan aplikasi ini, Anda setuju untuk terikat oleh Syarat dan Ketentuan berikut:\n\n'
              '1. Akun Pengguna\n'
              'Anda bertanggung jawab penuh atas menjaga kerahasiaan akun dan kata sandi Anda. Semua aktivitas yang terjadi di bawah akun Anda adalah tanggung jawab Anda.\n\n'
              '2. Penggunaan Aplikasi\n'
              'Aplikasi ini ditujukan untuk membeli barang thrift secara online. Dilarang menggunakan aplikasi untuk tujuan penipuan atau melanggar hukum.\n\n'
              '3. Transaksi\n'
              'Semua transaksi dilakukan antara pembeli dan aplikasi Thriftin. Harga dapat berubah sewaktu-waktu tanpa pemberitahuan sebelumnya.\n\n'
              '4. Kebijakan Pengembalian\n'
              'Barang yang sudah dibeli tidak dapat ditukar atau dikembalikan kecuali jika terjadi kesalahan dari pihak kami (misal: barang rusak atau salah kirim).\n\n'
              '5. Perubahan Syarat & Ketentuan\n'
              'Kami berhak mengubah syarat dan ketentuan ini kapan saja. Perubahan akan berlaku segera setelah dipublikasikan di aplikasi.',
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
