import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'wallet_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      if (authProvider.isAuthenticated && authProvider.token != null) {
        final messaging = FirebaseMessaging.instance;
        
        // Request notifications permission from the user
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          
          // Retrieve the device's FCM registration token
          final fcmToken = await messaging.getToken();
          if (fcmToken != null) {
            debugPrint('FCM Registration Token: $fcmToken');
            
            // Determine platform
            final platform = Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android';
            
            // Register FCM token via mobile client API
            await notificationProvider.registerDeviceToken(
              fcmToken,
              platform,
              authProvider.token!,
              headers: authProvider.headers,
            );
          }
        }

        // Subscribe to FCM registration token refresh stream
        messaging.onTokenRefresh.listen((newFcmToken) async {
          if (authProvider.isAuthenticated && authProvider.token != null) {
            final platform = Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android';
            await notificationProvider.registerDeviceToken(
              newFcmToken,
              platform,
              authProvider.token!,
              headers: authProvider.headers,
            );
          }
        }).onError((err) {
          debugPrint('FCM Token Refresh Error: $err');
        });
      }
    } catch (e) {
      debugPrint('FCM Registration Setup Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          WalletScreen(),
          TransactionHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: AppTheme.accentColor,
          unselectedItemColor: theme.hintColor.withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.qr_code_scanner_rounded)),
              label: 'home'.tr().toUpperCase(),
            ),
            BottomNavigationBarItem(
              icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_balance_wallet_rounded)),
              label: 'wallet'.tr().toUpperCase(),
            ),
            BottomNavigationBarItem(
              icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.history_rounded)),
              label: 'history'.tr().toUpperCase(),
            ),
            BottomNavigationBarItem(
              icon: const Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
              label: 'profile'.tr().toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }
}
