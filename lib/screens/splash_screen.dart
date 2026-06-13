import 'dart:async';

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
  late final AnimationController _progressController;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _start();
  }

  void _setupAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _contentOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));
    _contentOffset =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
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
    await _delay(const Duration(milliseconds: 120));
    if (!mounted) return;

    _introController.forward();
    _progressController.forward();

    await _delay(const Duration(milliseconds: 2100));
    if (!mounted) return;

    await _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final isLoggedIn = await UserService().loadSession();
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
      backgroundColor: AppColors.primary,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10B981),
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _contentOpacity,
                  child: SlideTransition(
                    position: _contentOffset,
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: 118,
                            height: 118,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.36),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/icons/icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ThriftIn',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Marketplace thrift dan preloved',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xDDFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _buildProgress(),
                const SizedBox(height: 22),
                const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xBBFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return FadeTransition(
      opacity: _contentOpacity,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, _) {
          return SizedBox(
            width: 168,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progressController.value,
                minHeight: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
