import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/trip_provider.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    
    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor,
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
                  final tripId = code.split('/').last;
                  try {
                    await tripProvider.fetchTripStatus(tripId, auth.token!);
                    if (mounted) {
                      Navigator.pushNamed(
                        context, 
                        '/confirm-payment', 
                        arguments: {'trip_id': tripId, 'amount': 15.0}
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid Trip QR: $e'))
                      );
                    }
                  }
                }
              }
            },
          ),
          _buildScannerOverlay(context),
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

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
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
                'Hi, ${auth.user?['name'] ?? 'Passenger'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
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
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final trip = context.watch<TripProvider>();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 500,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
                    title: 'My QR',
                    subtitle: 'Show to pay',
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/routes'),
                    child: _ActionCard(
                      icon: Icons.map_outlined,
                      title: 'Find Taxi',
                      subtitle: 'Routes',
                      color: Colors.orange.withOpacity(0.05),
                      iconColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
            Expanded(
              child: trip.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : trip.routes.isEmpty
                  ? const Center(child: Text('No routes available'))
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 12),
                      itemCount: trip.routes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final r = trip.routes[index];
                        return _TripItem(
                          title: '${r['startLocation']} → ${r['endLocation']}',
                          subtitle: 'Base Fare: ${r['baseFare']} ETB',
                          amount: '${r['distance']} km',
                        );
                      },
                    ),
            ),
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
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
