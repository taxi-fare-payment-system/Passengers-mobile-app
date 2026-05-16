import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.tryAutoLogin();
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppTheme.primaryColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    size: 64,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'WULO PAY',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 4,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'qr_based_taxi_payments'.tr().toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
