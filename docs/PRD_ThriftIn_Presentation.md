# Product Requirements Document (PRD) - ThriftIn

## 1. Ringkasan Produk

ThriftIn adalah aplikasi marketplace mobile untuk jual beli barang thrift atau preloved. Aplikasi ini membantu pengguna menemukan barang bekas berkualitas, menyimpan produk favorit, melakukan pembelian langsung, mengikuti live bidding, berkomunikasi dengan pengguna lain, dan memberi ulasan setelah transaksi.

Produk ini ditujukan untuk pengguna yang ingin membeli barang unik dengan harga lebih terjangkau sekaligus dapat menjual barang preloved miliknya sendiri dengan proses yang sederhana. Dalam ThriftIn, satu akun pengguna dapat berperan sebagai pembeli maupun penjual.

## 2. Latar Belakang Masalah

Pasar barang preloved semakin diminati karena harga lebih murah, pilihan barang unik, dan gaya konsumsi yang lebih berkelanjutan. Namun, proses jual beli barang thrift masih sering tersebar di media sosial atau chat pribadi sehingga pencarian produk, validasi penjual, negosiasi, dan transaksi menjadi kurang rapi.

ThriftIn hadir untuk membuat proses tersebut lebih terstruktur dalam satu aplikasi: discovery produk, detail produk, fitur favorit, live bidding, chat, checkout, notifikasi, dan review.

## 3. Tujuan Produk

- Mempermudah pembeli menemukan produk thrift berdasarkan kategori, pencarian, lokasi, kondisi, dan harga.
- Memudahkan pengguna menjual produk dengan foto, deskripsi, harga, kategori, kondisi, dan mode jual langsung atau bidding.
- Menyediakan pengalaman transaksi yang lebih lengkap melalui checkout, metode pembayaran, alamat pengiriman, dan status pesanan.
- Meningkatkan kepercayaan pengguna melalui review, rating, profil penjual, dan riwayat transaksi.
- Membuat proses negosiasi lebih interaktif melalui chat dan live bidding.

## 4. Target Pengguna

### Pengguna sebagai Pembeli

Pengguna yang mencari barang thrift atau preloved seperti pakaian, sepatu, tas, aksesoris, dan elektronik dengan harga terjangkau.

Kebutuhan utama:
- Melihat katalog produk dengan cepat.
- Mencari produk spesifik.
- Menyimpan produk favorit.
- Melakukan pembelian atau bidding.
- Menghubungi penjual.
- Melihat ulasan sebelum membeli.

### Pengguna sebagai Penjual

Pengguna yang ingin menjual barang pribadi, koleksi thrift, atau produk preloved.

Kebutuhan utama:
- Mengunggah produk dengan mudah.
- Mengelola informasi produk.
- Menerima chat dari calon pembeli.
- Menerima pesanan atau tawaran bidding.
- Mendapatkan review sebagai reputasi toko.

## 5. Value Proposition

ThriftIn menggabungkan katalog marketplace, live bidding, chat, dan review dalam satu aplikasi mobile. Saat berperan sebagai pembeli, pengguna mendapatkan pengalaman belanja yang lebih praktis. Saat berperan sebagai penjual, pengguna mendapatkan kanal penjualan yang lebih terstruktur dibanding hanya mengandalkan media sosial.

Satu akun ThriftIn tidak dibatasi ke satu role. Pengguna dapat membeli produk orang lain dan pada saat yang sama menjual produknya sendiri.

## 6. Ruang Lingkup MVP

### Fitur Utama

- Autentikasi pengguna: register, login, dan lengkapi profil.
- Beranda produk: menampilkan produk terbaru dan kategori.
- Pencarian produk: mencari berdasarkan nama, kategori, kondisi, toko, atau lokasi.
- Detail produk: foto, harga, rating, kondisi, deskripsi, toko, lokasi, dan review.
- Favorit: menyimpan produk yang diminati.
- Keranjang: menyimpan produk sebelum checkout.
- Jual produk: tambah produk dengan gambar, harga, kategori, kondisi, lokasi, dan deskripsi.
- Checkout: membuat pesanan dengan alamat, metode pengiriman, biaya layanan, diskon, dan metode pembayaran.
- Live bidding: produk dengan mode lelang, timer, tawaran tertinggi, dan daftar bid.
- Chat pembeli-penjual: ruang chat berbasis produk.
- Notifikasi: informasi aktivitas seperti transaksi, chat, atau update produk.
- Review: pembeli dapat memberi rating dan komentar setelah transaksi.
- Metode pembayaran: menyimpan pilihan pembayaran pengguna.
- Help center: pengguna dapat mengirim pesan bantuan.

### Di Luar Scope MVP

- Payment gateway nyata.
- Sistem escrow.
- Verifikasi identitas penjual.
- Integrasi kurir real-time.
- Admin dashboard.
- Moderasi konten otomatis.
- Rekomendasi produk berbasis machine learning.

## 7. User Journey Utama

### Journey Pengguna sebagai Pembeli

1. Pengguna membuka aplikasi dan melihat produk di beranda.
2. Pengguna memilih kategori atau mencari produk tertentu.
3. Pengguna membuka detail produk untuk melihat foto, deskripsi, rating, dan review.
4. Pengguna menyimpan produk ke favorit atau menghubungi penjual melalui chat.
5. Jika produk dijual langsung, pengguna melanjutkan ke checkout.
6. Jika produk lelang, pengguna memasukkan nominal bid sesuai minimal tawaran.
7. Setelah transaksi selesai, pengguna dapat memberi review.

### Journey Pengguna sebagai Penjual

1. Pengguna login dan melengkapi profil.
2. Pengguna membuka halaman jual produk.
3. Pengguna mengisi nama produk, harga, kategori, kondisi, lokasi, foto, dan deskripsi.
4. Pengguna memilih mode jual langsung atau bidding.
5. Produk tampil di katalog atau halaman live bidding.
6. Pengguna menerima chat, order, atau tawaran dari pembeli.
7. Pengguna mendapatkan rating dan review dari transaksi sebagai penjual.

## 8. Kebutuhan Fungsional

### Akun dan Profil

- Sistem harus dapat membuat akun pengguna baru.
- Sistem harus dapat menyimpan nama, email, password, nomor telepon, alamat, bio, foto profil, gender, dan tanggal lahir.
- Pengguna harus dapat memperbarui profil.

### Produk

- Sistem harus menampilkan daftar produk dengan pagination.
- Sistem harus menampilkan produk berdasarkan kategori.
- Sistem harus mendukung pencarian produk.
- Sistem harus menyimpan lebih dari satu gambar produk.
- Sistem harus mendukung produk normal dan produk bidding.

### Favorit

- Pengguna harus dapat menambah atau menghapus produk favorit.
- Sistem harus menampilkan daftar produk favorit milik pengguna.

### Bidding

- Sistem harus menampilkan produk yang sedang dilelang.
- Sistem harus menampilkan timer berakhirnya bidding.
- Sistem harus menyimpan tawaran pembeli.
- Tawaran baru harus lebih tinggi dari tawaran tertinggi atau harga awal.

### Checkout dan Order

- Sistem harus dapat menyimpan produk ke keranjang sebelum checkout.
- Sistem harus dapat membuat order dari produk.
- Sistem harus menyimpan pembeli, penjual, total pembayaran, metode pembayaran, alamat pengiriman, metode pengiriman, biaya kirim, biaya layanan, diskon, dan status order.

### Chat

- Sistem harus membuat ruang chat berdasarkan produk, pembeli, dan penjual.
- Sistem harus menyimpan pesan, pengirim, waktu kirim, status terbaca, dan nominal offer jika ada.

### Review

- Sistem harus mengizinkan pembeli memberi rating 1 sampai 5.
- Sistem harus menyimpan komentar review.
- Sistem harus menghubungkan review dengan produk, order, pembeli, dan penjual.

### Notifikasi

- Sistem harus menampilkan notifikasi per pengguna.
- Sistem harus membedakan notifikasi yang sudah dan belum dibaca.

## 9. Kebutuhan Non-Fungsional

- Performa: daftar produk menggunakan pagination agar layar tetap responsif.
- Skalabilitas: tabel produk, order, chat, dan bidding memiliki index untuk mempercepat query.
- Ketersediaan gambar: gambar produk dan foto profil disimpan di Supabase Storage bucket publik.
- Keamanan: database menggunakan Row Level Security. Untuk versi produksi, policy perlu diperketat agar pengguna hanya bisa mengakses atau mengubah data yang sesuai haknya.
- Kemudahan penggunaan: UI mobile harus sederhana, cepat dipahami, dan mendukung alur belanja dalam beberapa langkah.

## 10. Arsitektur Sistem

### Client

Aplikasi mobile dibangun menggunakan Flutter. Client bertanggung jawab untuk tampilan, navigasi, validasi input dasar, upload gambar, dan interaksi pengguna.

### Backend

Backend menggunakan Supabase sebagai layanan database PostgreSQL, storage, dan API data. Aplikasi mengakses tabel melalui Supabase client.

### Database Utama

- `users`: data akun dan profil pengguna.
- `products`: data produk, harga, kategori, kondisi, lokasi, dan mode bidding.
- `product_images`: galeri gambar produk.
- `user_favorites`: produk yang disimpan pengguna.
- `cart_items`: produk yang ditambahkan pengguna ke keranjang.
- `bids`: data tawaran bidding.
- `orders`: transaksi pembelian.
- `notifications`: notifikasi pengguna.
- `payment_methods`: metode pembayaran pengguna.
- `help_messages`: pesan bantuan.
- `chat_rooms`: ruang chat pembeli dan penjual.
- `chat_messages`: isi pesan chat.
- `reviews`: rating dan ulasan produk atau penjual.

## 11. Success Metrics

- Jumlah pengguna terdaftar.
- Jumlah produk yang diunggah.
- Jumlah pencarian produk.
- Jumlah produk yang ditambahkan ke favorit.
- Jumlah order yang dibuat.
- Jumlah bid pada produk lelang.
- Jumlah chat antara pembeli dan penjual.
- Jumlah review yang diberikan setelah transaksi.
- Conversion rate dari detail produk ke checkout atau bidding.

## 12. Risiko dan Mitigasi

### Risiko: Keamanan data masih terlalu terbuka

Saat ini policy RLS mengizinkan akses luas untuk role `anon` Supabase. Ini cocok untuk fase demo atau pengembangan, tetapi berisiko untuk produksi.

Mitigasi:
- Gunakan Supabase Auth.
- Batasi update dan delete berdasarkan user pemilik data.
- Jangan simpan password dalam bentuk plain text.
- Batasi akses berdasarkan kepemilikan data, misalnya pengguna hanya dapat mengubah profilnya sendiri, produk miliknya sendiri, dan data transaksi yang melibatkan dirinya.

### Risiko: Transaksi belum menggunakan pembayaran nyata

Checkout masih bersifat simulasi sehingga belum ada validasi pembayaran.

Mitigasi:
- Tambahkan payment gateway.
- Tambahkan status pembayaran.
- Tambahkan bukti pembayaran atau webhook pembayaran.

### Risiko: Penyalahgunaan produk atau chat

Marketplace publik berisiko memuat produk tidak layak atau pesan spam.

Mitigasi:
- Tambahkan fitur report produk.
- Tambahkan admin moderation.
- Tambahkan pembatasan upload dan validasi konten.

## 13. Roadmap Pengembangan

### Fase 1 - MVP

- Register dan login.
- Katalog produk.
- Detail produk.
- Upload produk.
- Favorit.
- Checkout simulasi.
- Live bidding.
- Chat.
- Review.

### Fase 2 - Production Readiness

- Integrasi Supabase Auth penuh.
- RLS berbasis user session.
- Password hashing atau migrasi ke auth provider.
- Payment gateway.
- Status pembayaran dan pengiriman.
- Admin dashboard dasar.

### Fase 3 - Growth

- Rekomendasi produk personal.
- Voucher dan promo.
- Sistem reputasi penjual.
- Push notification.
- Integrasi kurir.
- Moderasi produk dan report user.

## 14. Outline Slide Presentasi

1. Judul: ThriftIn - Marketplace Thrift dan Preloved
2. Problem: jual beli thrift masih tersebar dan kurang terstruktur.
3. Solution: satu aplikasi untuk katalog, bidding, chat, checkout, dan review.
4. Target User: satu pengguna bisa menjadi pembeli sekaligus penjual.
5. Core Features: produk, favorit, jual produk, checkout, bidding, chat, review.
6. User Journey Pengguna sebagai Pembeli: discovery sampai review.
7. User Journey Pengguna sebagai Penjual: upload produk sampai menerima transaksi.
8. System Architecture: Flutter + Supabase + Storage.
9. Data Model: users, products, orders, bids, chats, reviews.
10. Success Metrics: user, produk, order, bid, chat, review.
11. Risiko dan Mitigasi: security, payment, moderation.
12. Roadmap: MVP, production readiness, growth.

## 15. Kesimpulan

ThriftIn dirancang sebagai marketplace mobile yang fokus pada pengalaman jual beli barang thrift secara praktis, interaktif, dan terpercaya. Dengan fitur katalog, live bidding, chat, checkout, dan review, aplikasi ini dapat menjadi solusi yang lebih rapi untuk komunitas pembeli dan penjual barang preloved.
