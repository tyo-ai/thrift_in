import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_prefetch_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _backgroundAnimation;

  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _dismissKeyboardOnStart();
    _setupAnimations();
    _start();
  }

  void _dismissKeyboardOnStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  void _setupAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final logoCurve = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    );
    final textCurve = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(logoCurve);
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(logoCurve);

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(textCurve);
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(textCurve);

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _delay(Duration duration) {
    final completer = Completer<void>();
    final timer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    _timers.add(timer);
    return completer.future;
  }

  Future<void> _start() async {
    await _delay(const Duration(milliseconds: 200));
    if (!mounted) return;

    _introController.forward();
    _progressController.forward();

    await _delay(const Duration(milliseconds: 2500));
    if (!mounted) return;

    await _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    var isLoggedIn = false;
    try {
      isLoggedIn = await UserService().loadSession().timeout(
        const Duration(seconds: 5),
      );
    } catch (error) {
      debugPrint('Splash session check skipped: $error');
    }

    if (isLoggedIn) {
      try {
        await AppPrefetchService.instance.warmCritical();
        AppPrefetchService.instance.warmBackground();
      } catch (_) {
        AppPrefetchService.instance.warmBackground();
      }
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(isLoggedIn ? '/home' : '/login');
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _introController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: SplashBackgroundPainter(
              animationValue: _backgroundAnimation.value,
              primaryColor: AppColors.primary,
              darkColor: AppColors.primaryDark,
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              children: [
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/icons/icon.png',
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textOffset,
                    child: Column(
                      children: [
                        const Text(
                          'ThriftIn',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belanja thrift, hemat & stylish',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFE8F5E9)],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'v1.0.2',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SplashBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color darkColor;

  SplashBackgroundPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkColor, primaryColor],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final Paint wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    final double offset = animationValue * 40;

    wavePaint.color = primaryColor.withValues(alpha: 0.25);
    final Path topPath = Path();
    topPath.addOval(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.8 + math.sin(animationValue * math.pi) * 20,
          size.height * 0.15 - offset * 0.2,
        ),
        radius: size.width * 0.55,
      ),
    );
    canvas.drawPath(topPath, wavePaint);

    wavePaint.color = darkColor.withValues(alpha: 0.45);
    final Path bottomPath = Path();
    bottomPath.addOval(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.1 - math.cos(animationValue * math.pi) * 20,
          size.height * 0.85 + offset * 0.3,
        ),
        radius: size.width * 0.65,
      ),
    );
    canvas.drawPath(bottomPath, wavePaint);

    wavePaint.color = const Color(0xFF26A69A).withValues(alpha: 0.15);
    final Path middlePath = Path();
    middlePath.addOval(
      Rect.fromCircle(
        center: Offset(
          size.width * 0.5,
          size.height * 0.5 + math.sin(animationValue * 2 * math.pi) * 15,
        ),
        radius: size.width * 0.45,
      ),
    );
    canvas.drawPath(middlePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant SplashBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.darkColor != darkColor;
  }
}
