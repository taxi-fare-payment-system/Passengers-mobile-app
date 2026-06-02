import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/trip_details_screen.dart';
import 'screens/payment_screens.dart';
import 'screens/feedback_screens.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/top_up_screens.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/profile_management_screens.dart';
import 'screens/route_selection_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/qr_provider.dart';
import 'providers/document_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/feedback_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/driver_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  } else {
    debugPrint('Firebase messaging is bypassed on this platform (${Platform.operatingSystem})');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('am')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => TripProvider()),
          ChangeNotifierProvider(create: (_) => QRProvider()),
          ChangeNotifierProvider(create: (_) => DocumentProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => FeedbackProvider()),
          ChangeNotifierProvider(create: (_) => DriverProvider()),
        ],
        child: const WuloPayApp(),
      ),
    ),
  );
}

class WuloPayApp extends StatelessWidget {
  const WuloPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'WuloPay',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/language': (context) => const LanguageSelectionScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/otp': (context) => const OTPScreen(),
            '/home': (context) => const MainNavigation(),
            '/trip-details': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;              return TripDetailsScreen(route: args?['route']);
            },
            '/confirm-payment': (context) => const ConfirmPaymentScreen(),
            '/rate-trip': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return RateTripScreen(tripId: args?['tripId'] ?? 'unknown', driverId: args?['driverId']);
            },
            '/payment-methods': (context) => const PaymentMethodsScreen(),
            '/top-up': (context) => const TopUpScreen(),
            '/topup/success': (context) => const TopUpStatusScreen(isSuccess: true),
            '/topup/failed': (context) => const TopUpStatusScreen(isSuccess: false),
            '/top-up/success': (context) => const TopUpStatusScreen(isSuccess: true),
            '/top-up/failed': (context) => const TopUpStatusScreen(isSuccess: false),
            '/driver-profile': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return DriverProfileScreen(driverId: args?['driverId']);
            },
            '/transaction-history': (context) => const TransactionHistoryScreen(),
            '/transfer': (context) => const TransferScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/verification': (context) => const VerificationScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
            '/route-selection': (context) => const RouteSelectionScreen(),
          },
        );
      },
    );
  }
}
