# ThriftIn

ThriftIn adalah aplikasi marketplace mobile untuk jual beli barang thrift dan preloved. Aplikasi ini dibuat dengan Flutter dan Supabase, dengan fokus ke alur belanja yang cukup lengkap: lihat produk, simpan favorit, checkout, live bidding, chat penjual-pembeli, sampai review setelah transaksi.

Project ini masih ditujukan untuk kebutuhan pengembangan/demo, jadi beberapa bagian seperti policy database, payment flow, dan deployment backend masih perlu disesuaikan lagi kalau mau dipakai untuk produksi.

## Fitur

- Login, register, lengkapi profil, dan reset password dengan OTP.
- Beranda produk dengan kategori, pencarian, dan detail produk.
- Upload produk untuk dijual, termasuk foto, harga, kondisi, lokasi, dan deskripsi.
- Favorit dan keranjang belanja.
- Checkout dan riwayat pesanan.
- Mode live bidding untuk produk lelang.
- Chat antara pembeli dan penjual berdasarkan produk.
- Notifikasi aktivitas aplikasi.
- Review dan rating setelah transaksi.
- Laporan penjualan untuk penjual.
- Integrasi pembayaran Duitku sandbox lewat Supabase Edge Function.

## Teknologi

- Flutter
- Dart
- Supabase PostgreSQL
- Supabase Storage
- Supabase Edge Functions
- Duitku sandbox
- Resend untuk email OTP reset password

## Struktur Singkat

```text
lib/
  screens/      halaman utama aplikasi
  services/     akses data, Supabase, chat, order, payment, notifikasi
  widgets/      komponen UI yang dipakai ulang
  theme/        warna dan style aplikasi

supabase/
  functions/    edge function untuk Duitku dan reset password
  migrations/   migration tambahan

docs/
  PRD_ThriftIn_Presentation.md
```

## Menjalankan Project

Pastikan Flutter sudah terpasang, lalu jalankan:

```bash
flutter pub get
flutter run
```

Secara default aplikasi sudah punya konfigurasi Supabase di `lib/services/supabase_config.dart`. Kalau ingin memakai project Supabase lain, jalankan dengan `dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Setup Database

Skema utama ada di:

```text
supabase_schema.sql
```

Migration tambahan untuk OTP reset password ada di:

```text
supabase/migrations/20260612074545_add_password_reset_otps.sql
```

Untuk setup awal, import schema ke Supabase SQL editor atau jalankan lewat Supabase CLI sesuai kebutuhan project.

## Edge Function

Project ini memakai dua Edge Function:

- `create-duitku-transaction` untuk membuat transaksi Duitku sandbox.
- `password-reset-otp` untuk request dan verifikasi OTP reset password.

Contoh deploy:

```bash
supabase functions deploy create-duitku-transaction
supabase functions deploy password-reset-otp
```

Secret yang perlu disiapkan menyesuaikan function yang dipakai:

```bash
supabase secrets set DUITKU_MERCHANT_CODE=...
supabase secrets set DUITKU_API_KEY=...
supabase secrets set DUITKU_ENVIRONMENT=sandbox
supabase secrets set RESEND_API_KEY=...
supabase secrets set RESEND_FROM_EMAIL=...
supabase secrets set RESEND_FROM_NAME=ThriftIn
```

Catatan detail untuk Duitku ada di `supabase/functions/create-duitku-transaction/README.md`.

## Catatan Pengembangan

- Aplikasi memakai Supabase sebagai backend utama untuk data produk, user, order, chat, bidding, review, dan notifikasi.
- Beberapa flow masih dibuat untuk kebutuhan demo, terutama bagian transaksi dan keamanan database.
- Jika akan dilanjutkan ke produksi, bagian RLS policy, validasi pembayaran, dan penyimpanan password perlu ditinjau ulang lebih dulu.

## Dokumentasi

Dokumen kebutuhan produk dapat dilihat di:

```text
docs/PRD_ThriftIn_Presentation.md
```
