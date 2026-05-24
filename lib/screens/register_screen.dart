import 'package:flutter/material.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'buyer';

  // Colors
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimaryContainer = Color(0xFF00422B);
  static const Color primary = Color(0xFF006C49);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF3C4A42);
  static const Color outline = Color(0xFF6C7A71);
  static const Color outlineVariant = Color(0xFFBBCABF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: outline, fontSize: 16),
      filled: true,
      fillColor: surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      prefixIcon: Icon(icon, color: outline),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    Widget formContent = Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: _buildFormContent(isDesktop),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: surfaceContainerLow,
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildDesktopLeftPanel(),
            ),
            Expanded(
              flex: 7,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
                  child: formContent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: surfaceContainerLow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: formContent,
        ),
      ),
    );
  }

  Widget _buildDesktopLeftPanel() {
    return Container(
      color: primaryContainer,
      child: Stack(
        children: [
          // Background Image with Multiply blend mode
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCq2JeF9WzQcwCFRSZi99K-_QM3A4grqD6Kcg4IH-W7e0hzc8mWZQWuKSHntxF0LjkXlYmtTvE-rwADLfkAJbqMYbnRRjdBNmZ57Vj4Ev-NtF6MsfoXzGN5DQbNfmJcbEd7b_lRQayNH1hhzWsP6Bjt6aHzEGg6L_ezccuyzZ_ACDIrQMvYdDLk3J-4jA7KyUBSeP4XuHIHpvsqgHGw6v0z44K91SASutERrizsWMvjKODge1DTisS_5_3kidFPQbCGJa1ZCWWBmAIL',
                fit: BoxFit.cover,
                color: primaryContainer,
                colorBlendMode: BlendMode.multiply,
              ),
            ),
          ),
          // Abstract Glass Orbs
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 80,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ThriftIn',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: onPrimaryContainer,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bergabunglah dengan komunitas yang merayakan keberlanjutan dan gaya unik dalam setiap barang bekas berkualitas.',
                  style: TextStyle(
                    fontSize: 18,
                    color: onPrimaryContainer,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 40,
                            child: _buildAvatar(const Color(0xFFE7EEFE)),
                          ),
                          Positioned(
                            left: 20,
                            child: _buildAvatar(const Color(0xFFE2E8F8)),
                          ),
                          Positioned(
                            left: 0,
                            child: _buildAvatar(const Color(0xFFDCE2F3)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+10k Pengguna Bergabung',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color bgColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryContainer, width: 2),
        color: bgColor,
      ),
      child: const Center(
        child: Icon(Icons.person, color: primary, size: 20),
      ),
    );
  }

  Widget _buildFormContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop)
          const Center(
            child: Text(
              'ThriftIn',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
        if (!isDesktop) const SizedBox(height: 10),

        Text(
          'Daftar Akun Baru',
          style: TextStyle(
            fontSize: isDesktop ? 32 : 22,
            fontWeight: FontWeight.w700,
            color: onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Mulai perjalanan jual-beli barang bekas Anda.',
          style: TextStyle(
            fontSize: 13,
            color: outline,
          ),
        ),
        const SizedBox(height: 12),

        // Role Selection
        _buildLabel('Daftar Sebagai', 'role'),
        const SizedBox(height: 8),
        _buildRoleSelection(),
        const SizedBox(height: 16),

        // Nama Lengkap
        _buildLabel('Nama Lengkap', 'name'),
        const SizedBox(height: 4),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Masukkan nama lengkap Anda', Icons.person_outline),
        ),
        const SizedBox(height: 10),

        // Email
        _buildLabel('Email', 'email'),
        const SizedBox(height: 4),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('contoh@email.com', Icons.mail_outline),
        ),
        const SizedBox(height: 10),

        // Passwords
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Kata Sandi', 'password'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration('minimal 8 karakter', Icons.lock_outline,
                          suffixIcon: _buildPasswordVisibilityToggle(true)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Konfirmasi', 'confirm-password'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: _inputDecoration('ulangi kata sandi', Icons.verified_user_outlined,
                          suffixIcon: _buildPasswordVisibilityToggle(false)),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Kata Sandi', 'password'),
              const SizedBox(height: 4),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('minimal 8 karakter', Icons.lock_outline,
                    suffixIcon: _buildPasswordVisibilityToggle(true)),
              ),
              const SizedBox(height: 10),
              _buildLabel('Konfirmasi Kata Sandi', 'confirm-password'),
              const SizedBox(height: 4),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration('ulangi kata sandi', Icons.verified_user_outlined,
                    suffixIcon: _buildPasswordVisibilityToggle(false)),
              ),
            ],
          ),

        const SizedBox(height: 14),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              final confirm = _confirmController.text.trim();

              if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field harus diisi')),
                );
                return;
              }

              if (password.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kata sandi minimal 8 karakter')),
                );
                return;
              }

              if (password != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kata sandi dan konfirmasi tidak cocok')),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final result = await UserService().registerUser(
                name: name,
                email: email,
                password: password,
                role: _selectedRole,
              );
              if (result == -1) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Email sudah terdaftar')),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Pendaftaran berhasil! Silakan masuk.')),
                );
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryContainer,
              foregroundColor: onPrimaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: primaryContainer.withValues(alpha: 0.2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Daftar Sekarang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ATAU DAFTAR DENGAN',
                style: const TextStyle(
                  fontSize: 12,
                  color: outline,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: outlineVariant)),
          ],
        ),

        const SizedBox(height: 12),

        // Social Login
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDsIbbnBpsK1i8ZCyQqosKal9hWrXyhJ1BGOAEMoUrInO9wKbSEx6IhVoam2_QrlGFP9rStY2h5K96hTuT5RNhmDyAaFe4lvPpoGKvidlTSrCrqatFAxwxurtb4iHFqL-_MeJTXQ_N6eXK4X0p7sTCxvtO_7grrjVVfXoj0OKlKyAH2XP5PTOgc-chFU_W8LWOt8quxt1FY_252dU1wZowcZE9QpUj8Y7qotBB_d41tB3QEZ7yM3Vnb2miMLCNGSUwWqH3gdaTeCOjm',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24, color: onSurface),
                ),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                  side: const BorderSide(color: outlineVariant),
                  backgroundColor: surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_iphone, size: 20, color: onSurface),
                label: const Text('Apple'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurface,
                  side: const BorderSide(color: outlineVariant),
                  backgroundColor: surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Footer Link
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
              text: const TextSpan(
                text: 'Sudah punya akun? ',
                style: TextStyle(
                  fontSize: 16,
                  color: onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: 'Masuk',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Legal Info
        const Center(
          child: Text.rich(
            TextSpan(
              text: 'Dengan mendaftar, Anda menyetujui ',
              style: TextStyle(
                fontSize: 12,
                color: outline,
              ),
              children: [
                TextSpan(
                  text: 'Syarat & Ketentuan',
                  style: TextStyle(
                    color: onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' serta '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: TextStyle(
                    color: onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' ThriftIn.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, String id) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPasswordVisibilityToggle(bool isPassword) {
    final isObscure = isPassword ? _obscurePassword : _obscureConfirm;
    return IconButton(
      icon: Icon(
        isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: outline,
        size: 20,
      ),
      onPressed: () {
        setState(() {
          if (isPassword) {
            _obscurePassword = !_obscurePassword;
          } else {
            _obscureConfirm = !_obscureConfirm;
          }
        });
      },
    );
  }

  Widget _buildRoleSelection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = 'buyer'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedRole == 'buyer' ? primaryContainer : surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedRole == 'buyer' ? primaryContainer : outlineVariant,
                ),
              ),
              child: Center(
                child: Text(
                  'Pembeli',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedRole == 'buyer' ? onPrimaryContainer : outline,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = 'seller'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedRole == 'seller' ? primaryContainer : surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedRole == 'seller' ? primaryContainer : outlineVariant,
                ),
              ),
              child: Center(
                child: Text(
                  'Penjual',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedRole == 'seller' ? onPrimaryContainer : outline,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
