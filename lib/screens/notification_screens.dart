import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _NotificationItem(
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            title: 'Payment Successful',
            body: 'Your payment of 15.00 ETB for the ride to Stadium was successful.',
            time: '2 mins ago',
            isRead: false,
          ),
          const SizedBox(height: 16),
          _NotificationItem(
            icon: Icons.directions_car_rounded,
            iconColor: AppTheme.primaryColor,
            title: 'Driver Arriving',
            body: 'Your driver Dawit is 2 minutes away from your pickup point.',
            time: '15 mins ago',
            isRead: false,
          ),
          const SizedBox(height: 32),
          const Text('Earlier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _NotificationItem(
            icon: Icons.local_offer_rounded,
            iconColor: Colors.orange,
            title: 'Weekend Special!',
            body: 'Get 20% off on your next 3 rides this weekend. Use code WULOPROMO.',
            time: '2 hours ago',
            isRead: true,
          ),
          const SizedBox(height: 16),
          _NotificationItem(
            icon: Icons.system_update_rounded,
            iconColor: Colors.blue,
            title: 'App Update Available',
            body: 'A new version of WuloPay is available with improved performance and new features.',
            time: '1 day ago',
            isRead: true,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppTheme.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRead ? const Color(0xFFF1F5F9) : AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 14)),
                    Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _paymentAlerts = true;
  bool _tripUpdates = true;
  bool _promoOffers = false;
  bool _systemAnnouncements = true;
  bool _smsNotifications = false;
  bool _emailUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notification Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'All Notifications',
            'Receive all push notifications from the app',
            _pushNotifications,
            (v) => setState(() => _pushNotifications = v),
          ),
          const SizedBox(height: 32),
          const Text('Activity Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          _buildSwitchTile('Payment Alerts', 'Get notified about transactions', _paymentAlerts, (v) => setState(() => _paymentAlerts = v)),
          _buildSwitchTile('Trip Updates', 'Status of your rides', _tripUpdates, (v) => setState(() => _tripUpdates = v)),
          _buildSwitchTile('Promotions & Offers', 'Exclusive deals and discounts', _promoOffers, (v) => setState(() => _promoOffers = v)),
          _buildSwitchTile('System Announcements', 'Important app updates', _systemAnnouncements, (v) => setState(() => _systemAnnouncements = v)),
          const SizedBox(height: 32),
          const Text('Communication Channels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          _buildSwitchTile('SMS Notifications', 'Get updates via text message', _smsNotifications, (v) => setState(() => _smsNotifications = v)),
          _buildSwitchTile('Email Updates', 'Monthly summaries and reports', _emailUpdates, (v) => setState(() => _emailUpdates = v)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}
