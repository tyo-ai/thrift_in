import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/settings_screen.dart';
import 'services/user_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Cek sesi login yang tersimpan
  final isLoggedIn = await UserService().loadSession();

  runApp(ThriftinApp(isLoggedIn: isLoggedIn));
}

class ThriftinApp extends StatelessWidget {
  final bool isLoggedIn;
  const ThriftinApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thriftin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        fontFamily: 'Roboto',
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
      ),
      // Jika sudah login sebelumnya, langsung ke home. Jika tidak, ke login.
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/orders': (context) => const MyOrdersScreen(),
        '/payment-methods': (context) => const PaymentMethodsScreen(),
        '/help-center': (context) => const HelpCenterScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
