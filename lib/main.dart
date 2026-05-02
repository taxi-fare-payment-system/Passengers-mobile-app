import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/trip_details_screen.dart';
import 'screens/payment_screens.dart';
import 'screens/feedback_screens.dart';
import 'screens/payment_methods_screen.dart';

void main() {
  runApp(const WuloPayApp());
}

class WuloPayApp extends StatelessWidget {
  const WuloPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WuloPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OTPScreen(),
        '/home': (context) => const MainNavigation(),
        '/trip-details': (context) => const TripDetailsScreen(),
        '/confirm-payment': (context) => const ConfirmPaymentScreen(),
        '/rate-trip': (context) => const RateTripScreen(),
        '/payment-methods': (context) => const PaymentMethodsScreen(),
        '/top-up': (context) => const TopUpScreen(),
      },
    );
  }
}
