import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      context.read<NotificationProvider>().fetchNotifications(auth.token!, headers: auth.headers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('notifications'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppTheme.accentColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (notificationProvider.notifications.isNotEmpty)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(auth.token!, headers: auth.headers),
              child: Text(
                'read_all'.tr().toUpperCase(), 
                style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => notificationProvider.fetchNotifications(auth.token!, headers: auth.headers),
        color: AppTheme.accentColor,
        backgroundColor: theme.cardColor,
        child: _buildContent(notificationProvider, auth),
      ),
    );
  }

  Widget _buildContent(NotificationProvider provider, AuthProvider auth) {
    final theme = Theme.of(context);
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 80, color: theme.dividerColor.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('no_notifications_yet'.tr(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        final isUnread = notification['status'] != 'read';
        final date = DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              if (isUnread) {
                provider.markAsRead(notification['id'], auth.token!, headers: auth.headers);
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isUnread ? theme.cardColor : theme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isUnread ? AppTheme.accentColor.withOpacity(0.2) : theme.dividerColor.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(notification['category']).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getCategoryIcon(notification['category']), color: _getCategoryColor(notification['category']), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'] ?? 'notification'.tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isUnread ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(date),
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['content'] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'billing': case 'payment': return Icons.account_balance_wallet_rounded;
      case 'trip': return Icons.local_taxi_rounded;
      case 'security': return Icons.security_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'billing': case 'payment': return Colors.green;
      case 'trip': return AppTheme.accentColor;
      case 'security': return Colors.red;
      default: return Colors.blue;
    }
  }
}
