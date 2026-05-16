import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/wallet_provider.dart';
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

  Future<void> _fetchStops(String? tripId) async {
    if (tripId == null) return;
    setState(() => _isLoadingStops = true);
    try {
      final auth = context.read<AuthProvider>();
      final tripProvider = context.read<TripProvider>();
      await tripProvider.fetchNextStops(tripId, auth.token!, headers: auth.headers);
    } catch (e) {
      print('Error fetching stops: $e');
    } finally {
      setState(() => _isLoadingStops = false);
    }
  }

  Future<void> _handlePayment() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final tripId = args?['trip_id']?.toString();
    if (tripId == null) return;

    setState(() {
      _isPaying = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final tripProvider = context.read<TripProvider>();
      final wallet = context.read<WalletProvider>();
      
      final amount = double.tryParse(_amountController.text) ?? 0;
      
      final txId = await tripProvider.payFare(
        tripId: tripId,
        amount: amount,
        walletId: wallet.walletId ?? '',
        driverId: (tripProvider.currentTrip?['driver_id'] ?? tripProvider.currentTrip?['driverId'])?.toString() ?? '',
        token: auth.token!,
        headers: auth.headers,
      );

      // Auto-refresh wallet after payment
      final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString() ?? '';
      if (userId.isNotEmpty) {
        wallet.refreshWallet(userId, auth.token!);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(transactionId: txId, amount: amount),
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final tripId = args?['trip_id']?.toString() ?? 'unknown';
    final tripProvider = context.watch<TripProvider>();
    final auth = context.read<AuthProvider>();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('confirm_payment'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text('enter_amount_etb'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('where_getting_off'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Stops List
            if (_isLoadingStops) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (tripProvider.nextStops.isEmpty && (tripProvider.currentTrip?['route']?['stops'] as List?)?.isEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      'no_upcoming_stops'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'enter_qr_manually'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ] else ...[
              for (var stop in (tripProvider.nextStops.isNotEmpty 
                ? tripProvider.nextStops 
                : (tripProvider.currentTrip?['route']?['stops'] as List? ?? []))) 
                Builder(
                  builder: (context) {
                    final stopIndex = stop['stopIndex'] ?? stop['index'];
                    final isSelected = _selectedStopIndex == stopIndex;
                    final routeStops = tripProvider.currentTrip?['route']?['stops'] as List<dynamic>? ?? [];
                    final stopInfo = routeStops.firstWhere(
                      (s) => s['index'] == stopIndex || s['stopIndex'] == stopIndex,
                      orElse: () => null,
                    );
                    final stopName = stopInfo?['name'] ?? 'Stop $stopIndex';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          setState(() => _selectedStopIndex = stopIndex as int?);
                          if (stop['amount'] != null) {
                            setState(() => _amountController.text = stop['amount'].toString());
                          } else {
                            try {
                              final price = await tripProvider.fetchPriceQuote(
                                tripId: tripId,
                                destinationStopIndex: stopIndex as int,
                                token: auth.token!,
                                headers: auth.headers,
                              );
                              setState(() => _amountController.text = price.toStringAsFixed(2));
                            } catch (e) {
                              print('Price quote error: $e');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stopName,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (stop['distanceKm'] != null || stop['distance'] != null)
                                      Text(
                                        '${stop['distanceKm'] ?? stop['distance'] ?? '--'} km • ${stop['amount'] ?? '--'} ETB',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
            ],

            const SizedBox(height: 40),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isPaying 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('pay_fare'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String transactionId;
  final double amount;

  const PaymentSuccessScreen({super.key, required this.transactionId, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 100, color: Colors.green),
              const SizedBox(height: 32),
              Text('payment_successful'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'paid_for_trip'.tr(args: [amount.toStringAsFixed(2)]),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('transaction_id'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(transactionId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const RateTripScreen())
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('rate_your_trip'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                  child: Text('back_to_home'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentPinScreen extends StatelessWidget {
  final String tripId;
  final double amount;
  const PaymentPinScreen({super.key, required this.tripId, required this.amount});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('PIN Screen Placeholder')));
}
