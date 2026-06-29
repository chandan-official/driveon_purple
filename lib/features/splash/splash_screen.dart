import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/color_constants.dart';
import '../../api/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () async {
      final api = ApiService();
      final token = await api.loadToken();
      if (token != null && mounted) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedMode = prefs.getString('user_mode');

          if (savedMode == 'driver') {
            Navigator.pushReplacementNamed(context, '/driver_home');
            return;
          } else if (savedMode == 'rider') {
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }

          // Fallback to profile role check
          final profileRes = await api.getUserProfile();
          if (profileRes != null && profileRes['data'] != null && mounted) {
            final role = profileRes['data']['role'].toString().toUpperCase();
            final targetRoute = (role == 'DRIVER') ? '/driver_home' : '/home';
            Navigator.pushReplacementNamed(context, targetRoute);
            return;
          }
        } catch (_) {
          // Fallback to login on error
        }
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryPurple,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.56,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ryndo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Roboto',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Car Pooling | Cost Sharing',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
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
