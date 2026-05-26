import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers animasi
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  // Animasi logo
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _logoRotateAnim;

  // Animasi teks
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _taglineFadeAnim;

  // Animasi progress bar
  late Animation<double> _progressAnim;

  // Animasi pulse ring
  late Animation<double> _pulseScaleAnim;
  late Animation<double> _pulseOpacityAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo controller (0.8s)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Text controller (0.6s)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Progress controller (2.5s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Particle controller (3s loop)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Pulse controller (1.5s loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // --- Logo Animations ---
    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoRotateAnim = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // --- Text Animations ---
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // --- Progress Animation ---
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // --- Pulse Animations ---
    _pulseScaleAnim = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _pulseOpacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  void _startAnimationSequence() async {
    // Mulai animasi logo
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Mulai animasi teks
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textController.forward();

    // Mulai progress bar
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _progressController.forward();

    // Tunggu loading selesai lalu navigasi
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final isLoggedIn = await UserService().loadSession();
    if (!mounted) return;

    // Fade out sebelum navigasi
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      isLoggedIn ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D5C37),
              Color(0xFF1B8755),
              Color(0xFF25A96A),
              Color(0xFF1B8755),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background particle dots
            _buildParticles(),

            // Background decorative circles
            _buildDecorativeCircles(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo section with pulse ring
                  _buildLogoSection(),

                  const SizedBox(height: 32),

                  // App name + tagline
                  _buildTextSection(),

                  const SizedBox(height: 60),

                  // Loading indicator
                  _buildLoadingSection(),
                ],
              ),
            ),

            // Bottom brand text
            _buildBottomBrand(),
          ],
        ),
      ),
    );
  }

  // ─── Dekoratif lingkaran besar di background ───────────────────────────────
  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // Top-right large circle
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Top-right smaller
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Bottom-left large
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Bottom-left smaller
        Positioned(
          bottom: 60,
          left: 30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // Mid-left accent
        Positioned(
          top: 180,
          left: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Partikel bergerak ────────────────────────────────────────────────────
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  // ─── Logo dengan pulse ring ───────────────────────────────────────────────
  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, _) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring luar
              Transform.scale(
                scale: _pulseScaleAnim.value,
                child: Opacity(
                  opacity: _pulseOpacityAnim.value * _logoFadeAnim.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // Lingkaran latar logo
              FadeTransition(
                opacity: _logoFadeAnim,
                child: ScaleTransition(
                  scale: _logoScaleAnim,
                  child: Transform.rotate(
                    angle: _logoRotateAnim.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: _ThriftInLogo(size: 72),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Teks nama & tagline ──────────────────────────────────────────────────
  Widget _buildTextSection() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, _) {
        return FadeTransition(
          opacity: _textFadeAnim,
          child: SlideTransition(
            position: _textSlideAnim,
            child: Column(
              children: [
                // Nama aplikasi
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Thrift',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          shadows: [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: 'In',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB9F6CA),
                          letterSpacing: -1.5,
                          shadows: [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Divider tipis
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                FadeTransition(
                  opacity: _taglineFadeAnim,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '🛍️  Belanja Thrift, Hemat & Stylish',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.3,
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
  }

  // ─── Loading minimalis ─────────────────────────────────────────────────────
  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _pulseController]),
      builder: (context, _) {
        final progress = _progressAnim.value;
        final percent = (progress * 100).toInt();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis minimalis tipis
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final filledWidth = (totalWidth * progress).clamp(0.0, totalWidth);

                  return Stack(
                    children: [
                      // Track — garis abu sangat tipis
                      Container(
                        height: 1.5,
                        width: totalWidth,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      // Fill — garis putih dengan soft glow
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          // shimmer opacity pulse
                          final glowOpacity = 0.55 +
                              math.sin(_pulseController.value * math.pi * 2) *
                                  0.15;
                          return Container(
                            height: 1.5,
                            width: filledWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.5),
                                  Colors.white,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.white.withValues(alpha: glowOpacity),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Label kiri + persentase kecil kanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots wave + label status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Row(
                            children: List.generate(3, (i) {
                              final delay = i / 3.0;
                              final t =
                                  (_pulseController.value + delay) % 1.0;
                              final opacity =
                                  (math.sin(t * math.pi * 2) * 0.4 + 0.6)
                                      .clamp(0.15, 1.0);
                              return Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getLoadingLabel(progress),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  // Persentase kecil pojok kanan
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLoadingLabel(double progress) {
    if (progress < 0.3) return 'Memuat aplikasi...';
    if (progress < 0.6) return 'Menyiapkan katalog thrift...';
    if (progress < 0.85) return 'Mengecek sesi login...';
    return 'Hampir siap!';
  }

  // ─── Brand teks bawah ──────────────────────────────────────────────────────
  Widget _buildBottomBrand() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _textController,
        builder: (context, _) {
          return FadeTransition(
            opacity: _taglineFadeAnim,
            child: const Column(
              children: [
                Text(
                  'Temukan fashion thrift terbaik',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Color(0xAAFFFFFF),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: Color(0x77FFFFFF),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Logo Widget Custom ────────────────────────────────────────────────────────
class _ThriftInLogo extends StatelessWidget {
  final double size;
  const _ThriftInLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Warna utama hijau app
    final primaryPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = const Color(0xFF25A96A)
      ..style = PaintingStyle.fill;

    // === Gambar ikon pakaian/gantungan baju ===
    // Body baju (trapesium)
    final bodyPath = Path()
      ..moveTo(cx - size.width * 0.33, cy - size.height * 0.05)
      ..lineTo(cx - size.width * 0.38, cy + size.height * 0.35)
      ..lineTo(cx + size.width * 0.38, cy + size.height * 0.35)
      ..lineTo(cx + size.width * 0.33, cy - size.height * 0.05)
      ..lineTo(cx + size.width * 0.18, cy - size.height * 0.05)
      // Leher kanan
      ..quadraticBezierTo(
        cx + size.width * 0.12,
        cy - size.height * 0.22,
        cx,
        cy - size.height * 0.22,
      )
      // Leher kiri
      ..quadraticBezierTo(
        cx - size.width * 0.12,
        cy - size.height * 0.22,
        cx - size.width * 0.18,
        cy - size.height * 0.05,
      )
      ..close();
    canvas.drawPath(bodyPath, primaryPaint);

    // Lengan kiri baju
    final leftSleevePath = Path()
      ..moveTo(cx - size.width * 0.33, cy - size.height * 0.05)
      ..lineTo(cx - size.width * 0.18, cy - size.height * 0.05)
      ..quadraticBezierTo(
        cx - size.width * 0.12,
        cy - size.height * 0.22,
        cx,
        cy - size.height * 0.22,
      )
      ..quadraticBezierTo(
        cx - size.width * 0.08,
        cy - size.height * 0.32,
        cx - size.width * 0.22,
        cy - size.height * 0.30,
      )
      ..lineTo(cx - size.width * 0.48, cy - size.height * 0.08)
      ..close();
    canvas.drawPath(leftSleevePath, darkPaint);

    // Lengan kanan baju
    final rightSleevePath = Path()
      ..moveTo(cx + size.width * 0.33, cy - size.height * 0.05)
      ..lineTo(cx + size.width * 0.18, cy - size.height * 0.05)
      ..quadraticBezierTo(
        cx + size.width * 0.12,
        cy - size.height * 0.22,
        cx,
        cy - size.height * 0.22,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.08,
        cy - size.height * 0.32,
        cx + size.width * 0.22,
        cy - size.height * 0.30,
      )
      ..lineTo(cx + size.width * 0.48, cy - size.height * 0.08)
      ..close();
    canvas.drawPath(rightSleevePath, darkPaint);

    // Gantungan (hanger hook)
    final hangerPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;

    // Batang horizontal hanger
    canvas.drawLine(
      Offset(cx - size.width * 0.36, cy - size.height * 0.38),
      Offset(cx + size.width * 0.36, cy - size.height * 0.38),
      hangerPaint,
    );

    // Hook atas
    final hookPath = Path()
      ..moveTo(cx, cy - size.height * 0.38)
      ..lineTo(cx, cy - size.height * 0.52)
      ..quadraticBezierTo(
        cx,
        cy - size.height * 0.62,
        cx + size.width * 0.07,
        cy - size.height * 0.62,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.14,
        cy - size.height * 0.62,
        cx + size.width * 0.14,
        cy - size.height * 0.54,
      );

    final hookPaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hookPath, hookPaint);

    // Tag harga kecil di baju
    final tagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.10, cy + size.height * 0.12),
        width: size.width * 0.28,
        height: size.height * 0.18,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(tagRect, lightPaint);

    // Teks "Rp" di tag (garis simulasi)
    final tagTextPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Garis-garis kecil simulasi harga
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + size.width * 0.10, cy + size.height * 0.08),
          width: size.width * 0.16,
          height: size.height * 0.03,
        ),
        const Radius.circular(2),
      ),
      tagTextPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + size.width * 0.10, cy + size.height * 0.14),
          width: size.width * 0.12,
          height: size.height * 0.03,
        ),
        const Radius.circular(2),
      ),
      tagTextPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Particle Painter ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter(this.progress);

  static final List<_Particle> _particles = List.generate(20, (i) {
    final random = math.Random(i * 7 + 3);
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 4 + 2,
      speed: random.nextDouble() * 0.3 + 0.1,
      opacity: random.nextDouble() * 0.4 + 0.1,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final yPos = (p.y - progress * p.speed) % 1.0;
      final opacity = (math.sin(progress * math.pi * 2 + p.x * 10) * 0.2 +
              p.opacity)
          .clamp(0.0, 1.0);

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, yPos * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

