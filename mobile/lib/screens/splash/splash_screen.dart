import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _logoFade;

  static const _splashImages = [
    'assets/images/splash_1.png',
    'assets/images/splash_2.png',
    'assets/images/splash_3.png',
  ];

  late final String _bgImage;

  @override
  void initState() {
    super.initState();

    _bgImage = _splashImages[Random().nextInt(_splashImages.length)];

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));

    _scale = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 3000), _navigate);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    final route = token != null && token.isNotEmpty ? '/main' : '/login';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Room Image (changes every launch) ──
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                _bgImage,
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
              ),
            ),
          ),

          // ── Dark gradient overlay from bottom ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0xAA000000),
                  Color(0xEE000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Logo + tagline centered ──
          Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: size.width * 0.55,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Elevate Your Living Space',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD4A843),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading indicator at bottom ──
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: FadeTransition(
              opacity: _logoFade,
              child: Center(
                child: SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFFD4A843).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
