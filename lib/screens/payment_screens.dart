import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/qr_provider.dart';
import '../providers/notification_provider.dart';
import 'feedback_screens.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  int? _selectedStopIndex;
  bool _isLoadingStops = false;
  bool _isPaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['amount'] != null) {
          _amountController.text = args['amount'].toString();
        }
        _fetchStops(args['trip_id']?.toString());
      }
    });
  }

  Future<void> _fetchStops(String? qrCode) async {
    if (qrCode == null) return;
    setState(() => _isLoadingStops = true);
    try {
      final auth = context.read<AuthProvider>();
      final tripProvider = context.read<TripProvider>();
      
      // Check if the qrCode is already a valid UUID
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      final isUuid = uuidRegex.hasMatch(qrCode);
      
      if (isUuid) {
        // Fetch trip status to load currentTrip and fetch next stops directly
        await tripProvider.fetchTripStatus(qrCode, auth.token!, headers: auth.headers);
        await tripProvider.fetchNextStops(qrCode, auth.token!, headers: auth.headers);
      } else {
        // 1. Resolve Driver/Trip from QR
        final qrProvider = context.read<QRProvider>();
        final qrData = await qrProvider.getDriverFromQR(qrCode, auth.token!, headers: auth.headers);
        final driverId = qrData?['driver_id'];
        
        if (driverId != null) {
          // 2. Get active trip for this driver to get the REAL UUID
          await tripProvider.fetchActiveTripByDriver(driverId, auth.token!, headers: auth.headers);
          
          // 3. Use the real Trip UUID to fetch stops
          final realTripId = tripProvider.currentTrip?['id']?.toString();
          if (realTripId != null) {
            await tripProvider.fetchNextStops(realTripId, auth.token!, headers: auth.headers);
          }
        }
      }
    } catch (e) {
      print('Error fetching stops: $e');
    } finally {
      setState(() => _isLoadingStops = false);
    }
  }

  Future<void> _handlePayment() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final tripProvider = context.read<TripProvider>();
    final tripId = tripProvider.currentTrip?['id']?.toString() ?? args?['trip_id']?.toString();
    if (tripId == null) return;

    setState(() {
      _isPaying = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final wallet = context.read<WalletProvider>();
      
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        setState(() {
          _error = 'please_enter_valid_amount'.tr();
          _isPaying = false;
        });
        return;
      }
      
      final txId = await tripProvider.payFare(
        tripId: tripId,
        amount: amount,
        walletId: wallet.walletId ?? '',
        driverId: (tripProvider.currentTrip?['driver_id'] ?? tripProvider.currentTrip?['driverId'])?.toString() ?? '',
        token: auth.token!,
        headers: auth.headers,
      );

      final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString() ?? '';
      if (userId.isNotEmpty) {
        wallet.refreshWallet(userId, auth.token!);
        // Trigger notification and transaction refresh
        context.read<NotificationProvider>().fetchNotifications(auth.token!, headers: auth.headers);
        wallet.fetchTransactions(userId, auth.token!);
      }

      if (mounted) {
        final driverId = tripProvider.currentTrip?['driverId'] ?? tripProvider.currentTrip?['driver_id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              transactionId: txId, 
              amount: amount,
              tripId: tripId,
              driverId: driverId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isPaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('confirm_payment'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoadingStops
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.accentColor),
                  const SizedBox(height: 24),
                  Text('fetching_trip_details'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Driver Card
            if (tripProvider.currentTrip != null)
              GestureDetector(
                onTap: () {
                  final driverId = (tripProvider.currentTrip!['driver_id'] ?? tripProvider.currentTrip!['driverId'])?.toString();
                  if (driverId != null) {
                    Navigator.pushNamed(context, '/driver-profile', arguments: {'driverId': driverId});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFF101828),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_taxi_rounded, color: AppTheme.accentColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tripProvider.currentTrip!['driverName'] ?? 'assigned_soon'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                            ),
                            Text(
                              '${tripProvider.currentTrip!['route']?['start']?['metadata']?['name'] ?? '...'} → ${tripProvider.currentTrip!['route']?['end']?['metadata']?['name'] ?? '...'}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Amount Input
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text('enter_amount_currency'.tr(args: ['currency'.tr()]).toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: -2),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Text('where_getting_off'.tr().toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            
            // Stops Grid
            for (var stop in (tripProvider.nextStops.isNotEmpty 
              ? tripProvider.nextStops 
              : (tripProvider.currentTrip?['route']?['stops'] as List? ?? []))) 
                _StopItem(
                  stop: stop,
                  isSelected: _selectedStopIndex == (stop['stopIndex'] ?? stop['index'] ?? stop['sequence']),
                  onTap: () async {
                    final stopIndex = stop['stopIndex'] ?? stop['index'] ?? stop['sequence'];
                    setState(() => _selectedStopIndex = stopIndex as int?);
                    if (stop['amount'] != null) {
                      final parsedAmount = double.tryParse(stop['amount'].toString())?.toStringAsFixed(2) ?? stop['amount'].toString();
                      setState(() => _amountController.text = parsedAmount);
                    } else {
                      try {
                        final price = await tripProvider.fetchPriceQuote(
                          tripId: tripProvider.currentTrip?['id']?.toString() ?? (ModalRoute.of(context)?.settings.arguments as Map?)?['trip_id']?.toString() ?? '',
                          destinationStopIndex: stopIndex as int,
                          token: auth.token!,
                          headers: auth.headers,
                        );
                        setState(() => _amountController.text = price.toStringAsFixed(2));
                      } catch (e) {
                        final baseFare = tripProvider.currentTrip?['route']?['baseFare'];
                        if (baseFare != null) {
                          final parsedBase = double.tryParse(baseFare.toString())?.toStringAsFixed(2) ?? baseFare.toString();
                          setState(() => _amountController.text = parsedBase);
                        }
                      }
                    }
                  },
                ),

            const SizedBox(height: 40),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),

            ElevatedButton(
              onPressed: _isPaying ? null : _handlePayment,
              child: _isPaying 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : Text('pay_fare'.tr().toUpperCase()),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StopItem extends StatelessWidget {
  final dynamic stop;
  final bool isSelected;
  final VoidCallback onTap;

  const _StopItem({required this.stop, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String stopName = stop['name'] ?? 'Stop';
    if (stop['metadata']?['name'] != null) stopName = stop['metadata']['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentColor : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppTheme.accentColor : Theme.of(context).dividerColor.withOpacity(0.05),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: isSelected ? Colors.black : Colors.grey[400]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stopName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isSelected ? Colors.black : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (stop['distanceKm'] != null)
                      Text(
                        '${stop['distanceKm']} km',
                        style: TextStyle(fontSize: 12, color: isSelected ? Colors.black.withOpacity(0.6) : Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              if (stop['amount'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '${double.tryParse(stop['amount'].toString())?.toStringAsFixed(2) ?? stop['amount']} ${'currency'.tr()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isSelected ? Colors.black : AppTheme.accentColor,
                    ),
                  ),
                ),
              if (isSelected && stop['amount'] == null) 
                const Icon(Icons.check_circle_rounded, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String transactionId;
  final double amount;
  final String tripId;
  final String? driverId;

  const PaymentSuccessScreen({
    super.key, 
    required this.transactionId, 
    required this.amount,
    required this.tripId,
    this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 40),
            Text('payment_successful'.tr(), style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
            const SizedBox(height: 16),
            Text(
              'paid_for_trip'.tr(args: [amount.toStringAsFixed(2), 'currency'.tr()]),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 60),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => RateTripScreen(tripId: tripId, driverId: driverId))
              ),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
              child: Text('rate_your_trip'.tr().toUpperCase()),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
              child: Text('back_to_home'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
