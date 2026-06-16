import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://esvohuhgbrvoglmrbzrf.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_qQnVqzIq0d3xz9xF63zqhg_a2ItpgfJ',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client {
    if (!isConfigured) {
      throw StateError(
        'Supabase belum dikonfigurasi. Jalankan app dengan '
        '--dart-define=SUPABASE_URL=... dan '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    return Supabase.instance.client;
  }
}
