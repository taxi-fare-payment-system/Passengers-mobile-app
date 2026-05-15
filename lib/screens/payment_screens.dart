import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/wallet_provider.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  int? _selectedStopIndex;
  bool _isPaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['amount'] != null) {
        _amountController.text = args['amount'].toString();
      }
    });
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
        driverId: tripProvider.currentTrip?['driver_id']?.toString() ?? '',
        token: auth.token!,
      );

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
    
    final currentTrip = tripProvider.currentTrip;
    final stops = currentTrip?['route']?['stops'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  const Text('Enter Amount (ETB)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
            const Text('Where are you getting off?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Stops List
            if (stops.isEmpty)
              const Text('No route information available', style: TextStyle(color: AppTheme.textSecondary))
            else
              ...List.generate(stops.length, (index) {
                final stop = stops[index];
                final isSelected = _selectedStopIndex == index;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      setState(() => _selectedStopIndex = index);
                      try {
                        final price = await tripProvider.fetchPriceQuote(
                          tripId: tripId,
                          destinationStopIndex: index,
                          token: auth.token!,
                        );
                        setState(() => _amountController.text = price.toStringAsFixed(2));
                      } catch (e) {
                        print('Price quote error: $e');
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
                            child: Text(
                              stop['name'] ?? 'Unknown Stop',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                );
              }),

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
                  : const Text('Pay Fare', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
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
              const Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'You have paid ETB ${amount.toStringAsFixed(2)} for your trip.',
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
                    const Text('Transaction ID', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(transactionId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                  child: const Text('Back to Home'),
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
