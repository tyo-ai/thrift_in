import 'dart:async';

import 'package:flutter/material.dart';

import '../services/password_reset_service.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final PasswordResetService _resetService = PasswordResetService();

  Timer? _resendTimer;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Masukkan email yang valid', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _resetService.requestOtp(email);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _otpController.clear();
      });
      _startResendCooldown();
      _showMessage('Kode OTP sudah dikirim ke email.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Gagal mengirim OTP: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (otp.length != 6) {
      _showMessage('OTP harus 6 digit', isError: true);
      return;
    }
    if (password.length < 8) {
      _showMessage('Password minimal 8 karakter', isError: true);
      return;
    }
    if (password != confirm) {
      _showMessage('Konfirmasi password tidak sama', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _resetService.resetPassword(
        email: email,
        code: otp,
        newPassword: password,
      );
      if (!mounted) return;
      _showMessage('Password berhasil diubah. Silakan masuk.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Gagal reset password: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _editEmail() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _resendSeconds = 0;
      _otpController.clear();
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'email@example.com',
                icon: Icons.email_outlined,
                enabled: !_otpSent && !_isLoading,
                keyboardType: TextInputType.emailAddress,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                _buildOtpNotice(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _otpController,
                  label: 'Kode OTP',
                  hint: '6 digit OTP',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password Baru',
                  hint: 'Minimal 8 karakter',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmController,
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password baru',
                  icon: Icons.lock_reset_outlined,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _resetPassword : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _otpSent ? 'Memproses...' : 'Mengirim kode...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _otpSent ? 'Ubah Password' : 'Kirim OTP',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading || _resendSeconds > 0
                        ? null
                        : _sendOtp,
                    child: Text(
                      _resendSeconds > 0
                          ? 'Kirim ulang dalam $_resendSeconds detik'
                          : 'Kirim ulang OTP',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _otpSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _otpSent ? 'Cek email kamu' : 'Reset kata sandi',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _otpSent
              ? 'Kami mengirim kode 6 digit untuk verifikasi akun.'
              : 'Masukkan email akunmu, nanti kami kirim kode OTP untuk membuat password baru.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpNotice() {
    final email = _emailController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kode berlaku 10 menit. Cek juga folder spam kalau email belum masuk.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _editEmail,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Ganti email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: Icon(icon, color: AppColors.textHint),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
