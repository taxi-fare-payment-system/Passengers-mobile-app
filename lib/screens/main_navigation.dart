import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
