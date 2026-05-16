import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/qr_provider.dart';
import 'vehicle_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final auth = context.read<AuthProvider>();
    final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString();
    if (auth.token != null && userId != null) {
      context.read<WalletProvider>().fetchBalance(userId, auth.token!, headers: auth.headers);
      context.read<TripProvider>().fetchRoutes(auth.token!, headers: auth.headers);
      context.read<NotificationProvider>().fetchNotifications(auth.token!, headers: auth.headers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    
    if (isDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildHeader(context),
              ),
              Expanded(child: _buildDashboardContent(context)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  final auth = context.read<AuthProvider>();
                  final tripProvider = context.read<TripProvider>();
                  final qrProvider = context.read<QRProvider>();
                  
                  _handleQRValue(code, qrProvider, auth, tripProvider);
                }
              }
            },
          ),
          _buildScannerOverlay(context),
          // Manual Input Button for Computer/Debug
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () => _showManualQRDialog(),
              icon: const Icon(Icons.keyboard_rounded),
              label: Text('enter_qr_manually'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: _buildHeader(context),
          ),
          _buildDashboardContent(context),
        ],
      ),
    );
  }

  void _showManualQRDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('enter_qr_manually'.tr()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Paste QR value here'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(context);
                // Simulate scan detection
                final qrProvider = this.context.read<QRProvider>();
                final auth = this.context.read<AuthProvider>();
                final tripProvider = this.context.read<TripProvider>();
                
                _handleQRValue(val, qrProvider, auth, tripProvider);
              }
            },
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQRValue(String code, QRProvider qrProvider, AuthProvider auth, TripProvider tripProvider) async {
    // 1. Resolve Driver/Trip
    try {
      if (code.contains('/') && !code.contains('eyJ')) {
        // Legacy Trip URL format
        final tripId = code.split('/').last;
        await tripProvider.fetchTripStatus(tripId, auth.token!);
        if (mounted) {
          Navigator.pushNamed(context, '/confirm-payment', arguments: {'trip_id': tripId});
        }
      } else {
        // Driver QR format (Official /driver endpoint or Base64 Fallback)
        final driverInfo = await qrProvider.getDriverFromQR(code, auth.token!, headers: auth.headers);
        if (driverInfo != null && driverInfo['driver_id'] != null) {
          final driverId = driverInfo['driver_id'];
          await tripProvider.fetchActiveTripByDriver(driverId, auth.token!, headers: auth.headers);
          
          if (mounted && tripProvider.currentTrip != null) {
            Navigator.pushNamed(
              context, 
              '/confirm-payment', 
              arguments: {'trip_id': tripProvider.currentTrip!['id']}
            );
          }
        } else {
          // General verification if not a driver QR
          final isValid = await qrProvider.verifyQRCode(code, auth.token!, headers: auth.headers);
          if (!isValid && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_qr_code'.tr())));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')))
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                '${'hi'.tr()}, ${auth.user?['name'] ?? 'passenger'.tr()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none_rounded, color: Theme.of(context).iconTheme.color),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
                if (context.watch<NotificationProvider>().unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${context.watch<NotificationProvider>().unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${wallet.balance ?? '0'} ETB',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveTripCard(BuildContext context, TripProvider trip) {
    final t = trip.currentTrip!;
    final stops = t['route']?['stops'] as List<dynamic>? ?? [];
    final currentIdx = int.tryParse(t['currentStopIndex']?.toString() ?? '0') ?? 0;
    final currentStop = stops.isNotEmpty && currentIdx < stops.length ? stops[currentIdx]['name'] : 'in_transit'.tr();
    
    return InkWell(
      onTap: () {
        if (trip.vehicleDetails != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(vehicle: trip.vehicleDetails!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.local_taxi_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ongoing_trip'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        '${'next'.tr()}: $currentStop',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  child: Text('live'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: stops.isEmpty ? 0.5 : (currentIdx + 1) / stops.length,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final trip = context.watch<TripProvider>();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 500,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.qr_code_2_rounded,
                    title: 'my_qr'.tr(),
                    subtitle: 'show_to_pay'.tr(),
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _showManualQRDialog(),
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'pay_fare'.tr(),
                      subtitle: 'scan_or_enter_qr'.tr(),
                      color: Colors.green.withOpacity(0.05),
                      iconColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.transparent)),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 4), borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: iconColor.withOpacity(0.8), fontSize: 11)),
        ],
      ),
    );
  }
}

class _TripItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  const _TripItem({required this.title, required this.subtitle, required this.amount});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.directions_bus_filled_outlined, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}
