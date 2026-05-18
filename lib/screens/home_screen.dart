import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/qr_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/wallet_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(context),
                  const SizedBox(height: 48),
                  _buildSectionHeader(context, 'quick_actions'.tr()),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 48),
                  _buildManualQRSection(context),
                  const SizedBox(height: 60),
                  _buildSectionHeader(context, 'recent_trips'.tr()),
                  const SizedBox(height: 24),
                  _buildTripsList(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('welcome_back'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.hintColor.withOpacity(0.5))),
            Text(
              auth.user?['display_name'] ?? auth.user?['name'] ?? 'user'.tr(),
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: theme.textTheme.bodyLarge?.color, size: 30),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (context.watch<NotificationProvider>().unreadCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('wulopay_balance'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accentColor, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${wallet.balance ?? '0.00'} ${'currency'.tr()}',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, color: AppTheme.accentColor, letterSpacing: -1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(16)),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 24),
                  onPressed: () => _showQRScanner(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor.withOpacity(0.5)),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionItem(
          icon: Icons.qr_code_rounded,
          label: 'scan_pay'.tr(),
          onTap: () => _showQRScanner(context), 
        ),
        _QuickActionItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'top_up'.tr(),
          onTap: () => Navigator.pushNamed(context, '/top-up'),
        ),
        _QuickActionItem(
          icon: Icons.history_rounded,
          label: 'history'.tr(),
          onTap: () => Navigator.pushNamed(context, '/transaction-history'),
        ),
      ],
    );
  }

  Widget _buildManualQRSection(BuildContext context) {
    final qrProvider = context.watch<QRProvider>();
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('manual_qr_entry'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'enter_trip_code'.tr(),
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  onPressed: () async {
                    final code = controller.text.trim();
                    if (code.isEmpty) return;
                    try {
                      final isValid = await qrProvider.verifyQRCode(code, auth.token!, headers: auth.headers);
                      if (context.mounted) {
                        if (isValid) {
                          Navigator.pushNamed(context, '/confirm-payment', arguments: {'trip_id': code});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_qr_code'.tr())));
                        }
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final theme = Theme.of(context);
    if (tripProvider.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    if (tripProvider.tripHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car_rounded, size: 48, color: theme.dividerColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('no_trips_yet'.tr(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    return Column(
      children: tripProvider.tripHistory.take(3).map((trip) => _TripItem(trip: trip)).toList(),
    );
  }

  void _showQRScanner(BuildContext context) {
    bool hasScanned = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(modalContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(modalContext).dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('scan_pay'.tr().toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: MobileScanner(
                    onDetect: (capture) async {
                      if (hasScanned) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue?.trim();
                        if (code != null) {
                          hasScanned = true;
                          Navigator.pop(modalContext);
                          final auth = context.read<AuthProvider>();
                          final qrProvider = context.read<QRProvider>();
                          
                          try {
                            final isValid = await qrProvider.verifyQRCode(code, auth.token!, headers: auth.headers);
                            if (context.mounted) {
                              if (isValid) {
                                Navigator.pushNamed(context, '/confirm-payment', arguments: {'trip_id': code});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_qr_code'.tr())));
                              }
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.pop(modalContext), 
              child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary))
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: (width - 64 - 32) / 3, // Dynamic width for responsiveness
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 32),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripItem extends StatelessWidget {
  final dynamic trip;
  const _TripItem({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(trip['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_taxi_rounded, color: AppTheme.accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip['start_location']} → ${trip['end_location']}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat.yMMMd(context.locale.toString()).format(date),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(
            '${trip['estimated_fare']} ${'currency'.tr()}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.accentColor),
          ),
        ],
      ),
    );
  }
}
