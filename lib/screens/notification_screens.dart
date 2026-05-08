import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notifyProvider = context.read<NotificationProvider>();
      notifyProvider.fetchNotifications(auth.token!);
      notifyProvider.connectToStream(auth.user?['id'].toString() ?? '', auth.token!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifyProvider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();

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
            onPressed: () {
              // Implementation for mark all read
            },
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      body: notifyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifyProvider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No notifications yet', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: notifyProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifyProvider.notifications[index];
                    final isRead = n['status'] == 'read';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: isRead ? null : () => notifyProvider.markAsRead(n['id'].toString(), auth.token!),
                        onLongPress: !isRead ? null : () => notifyProvider.markAsUnread(n['id'].toString(), auth.token!),
                        child: _NotificationItem(
                          icon: _getIconForType(n['type']),
                          iconColor: _getColorForType(n['type']),
                          title: n['title'] ?? 'Notification',
                          body: n['content'] ?? '',
                          time: _formatTime(n['created_at']),
                          isRead: isRead,
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'payment_success': return Icons.check_circle_rounded;
      case 'trip_update': return Icons.directions_car_rounded;
      case 'promo': return Icons.local_offer_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'payment_success': return Colors.green;
      case 'trip_update': return AppTheme.primaryColor;
      case 'promo': return Colors.orange;
      default: return Colors.blue;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'now';
    final date = DateTime.tryParse(timestamp) ?? DateTime.now();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
