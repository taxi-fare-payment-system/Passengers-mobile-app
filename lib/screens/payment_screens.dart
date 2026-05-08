import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfirmPaymentScreen extends StatelessWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final tripId = args?['trip_id'] ?? 'unknown';
    final amount = args?['amount'] ?? 15.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Confirmation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Text('Trip Fare', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    'ETB ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _PaymentMethodSelector(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.1)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment will be deducted from your wallet.',
                      style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPinScreen(tripId: tripId, amount: amount),
                  ),
                );
              },
              child: const Text('Pay Now'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel Payment', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Available Balance: ETB 450.00', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class PaymentPinScreen extends StatelessWidget {
  final String tripId;
  final double amount;
  const PaymentPinScreen({super.key, required this.tripId, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Payment PIN Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Enter your 4-digit security PIN to authorize this payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0 ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                ),
              )),
            ),
            const Spacer(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox.shrink();
                if (index == 10) return _KeyButton('0', onTap: () {});
                if (index == 11) return IconButton(onPressed: () {}, icon: const Icon(Icons.backspace_outlined, size: 28));
                return _KeyButton('${index + 1}', onTap: () {
                  if (index == 2) { // Simulate correct PIN for demo
                     Navigator.pushReplacement(
                       context, 
                       MaterialPageRoute(builder: (context) => ProcessingPaymentScreen(tripId: tripId, amount: amount))
                     );
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _KeyButton(this.text, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(shape: const CircleBorder()),
      child: Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }
}

class ProcessingPaymentScreen extends StatefulWidget {
  final String tripId;
  final double amount;
  const ProcessingPaymentScreen({super.key, required this.tripId, required this.amount});

  @override
  State<ProcessingPaymentScreen> createState() => _ProcessingPaymentScreenState();
}

class _ProcessingPaymentScreenState extends State<ProcessingPaymentScreen> {
  @override
  void initState() {
    super.initState();
    _pay();
  }

  Future<void> _pay() async {
    try {
      final auth = context.read<AuthProvider>();
      final tripProvider = context.read<TripProvider>();
      
      final transactionId = await tripProvider.payFare(
        tripId: widget.tripId,
        amount: widget.amount,
        userId: auth.user?['id'].toString() ?? '',
        phone: auth.user?['phone'] ?? '',
        token: auth.token!,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => PaymentSuccessScreen(
            amount: widget.amount, 
            transactionId: transactionId,
          ))
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentCancelledScreen()));
      }
    }
  }

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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), shape: BoxShape.circle),
                child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3)),
              ),
              const SizedBox(height: 40),
              const Text('Processing Payment...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Please wait while we confirm your payment with the server. Do not close the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String transactionId;
  const PaymentSuccessScreen({super.key, required this.amount, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final trip = context.read<TripProvider>().currentTrip;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 32),
              const Text('Payment Successful!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Your transaction was completed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _ReceiptRow(label: 'Amount Paid', value: '${amount.toStringAsFixed(2)} ETB'),
                    const Divider(height: 32),
                    _ReceiptRow(label: 'Driver', value: trip?['driver_name'] ?? 'Assigned Driver'),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'Trip ID', value: '#${trip?['id']?.toString().substring(0, 8) ?? 'TRIP'}'),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'Transaction ID', value: '#${transactionId.substring(0, 12)}'),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'Date & Time', value: DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TripReceiptScreen())),
                child: const Text('View Receipt'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentCancelledScreen extends StatelessWidget {
  const PaymentCancelledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2), // Beige background from Figma
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 80),
              ),
              const SizedBox(height: 40),
              const Text('Payment Cancelled', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'The transaction was cancelled by the user or there was insufficient funds in your wallet. Please check your balance and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to Home', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TripReceiptScreen extends StatelessWidget {
  const TripReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Trip Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Map Placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  'https://api.placeholder.com/600/300',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  const Text('Trip Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Oct 12, 2023 • 10:35 AM', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const Divider(height: 48),
                  _ReceiptRow(label: 'Trip Distance', value: '6.2 km'),
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'Trip Duration', value: '18 mins'),
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'Vehicle Plate', value: '2-A34567'),
                  const Divider(height: 48),
                  _ReceiptRow(label: 'Fare Amount', value: '14.50 ETB'),
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'Service Fee', value: '0.50 ETB'),
                  const Divider(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('15.00 ETB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
