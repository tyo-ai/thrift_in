import 'supabase_config.dart';

class PasswordResetService {
  Future<void> requestOtp(String email) async {
    await _invoke({'action': 'request', 'email': email.trim().toLowerCase()});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _invoke({
      'action': 'reset',
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
      'newPassword': newPassword,
    });
  }

  Future<void> _invoke(Map<String, dynamic> body) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'password-reset-otp',
      body: body,
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
  }
}
