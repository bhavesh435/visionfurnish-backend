import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/providers.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/ar/image_to_ar_screen.dart';
import 'main_shell.dart';

void main() {
  runApp(const VisionFurnishApp());
}

class VisionFurnishApp extends StatelessWidget {
  const VisionFurnishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'VisionFurnish',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/auth-gate': (_) => const _AuthGate(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/main': (_) => const MainShell(),
          '/orders': (_) => const OrdersScreen(),
          '/scan-ar': (_) => const ImageToArScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.tryAutoLogin();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, ok ? '/main' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
    );
  }
}
