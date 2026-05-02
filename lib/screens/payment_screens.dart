import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfirmPaymentScreen extends StatelessWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    'Trip Fare',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '15.00 ETB',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _PaymentDetailRow(label: 'From', value: 'Megenagna Station'),
            _PaymentDetailRow(label: 'To', value: 'Stadium'),
            _PaymentDetailRow(label: 'Vehicle', value: 'Taxi - Plate 2-A34567'),
            const Divider(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Wallet Balance', style: TextStyle(color: AppTheme.textSecondary)),
                const Text('450.75 ETB', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentPinScreen()),
                );
              },
              child: const Text('Pay Now'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your payment of 15.00 ETB has been processed successfully.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _ReceiptRow(label: 'Transaction ID', value: '#TXN987654321'),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'Date', value: '24 Jan 2024'),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'Time', value: '10:35 AM'),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TripReceiptScreen()));
                },
                child: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class PaymentPinScreen extends StatelessWidget {
  const PaymentPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Enter Payment PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Please enter your 4-digit PIN to authorize the payment.', textAlign: TextAlign.center),
            const SizedBox(height: 48),
            // Placeholder for PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
              )),
            ),
            const Spacer(),
            // Numeric Keypad Placeholder
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
                if (index == 11) return IconButton(onPressed: () {}, icon: const Icon(Icons.backspace_outlined));
                return _KeyButton('${index + 1}', onTap: () {
                  if (index == 2) { // Simulate correct PIN entry on '3'
                     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProcessingPaymentScreen()));
                  }
                });
              },
            ),
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
      child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }
}

class ProcessingPaymentScreen extends StatefulWidget {
  const ProcessingPaymentScreen({super.key});

  @override
  State<ProcessingPaymentScreen> createState() => _ProcessingPaymentScreenState();
}

class _ProcessingPaymentScreenState extends State<ProcessingPaymentScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            const Text('Processing Payment...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please do not close the app.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.red, size: 60),
            ),
            const SizedBox(height: 32),
            const Text('Payment Cancelled', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('The transaction was cancelled by the user or timed out.', textAlign: TextAlign.center),
            const SizedBox(height: 48),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Try Again')),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Home')),
          ],
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
      appBar: AppBar(
        title: const Text('Trip Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('15.00 ETB', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const Divider(height: 48),
                  _ReceiptRow(label: 'Trip Date', value: '24 Jan 2024'),
                  _ReceiptRow(label: 'Trip ID', value: '#TRP123456'),
                  _ReceiptRow(label: 'Driver', value: 'Dawit K.'),
                  _ReceiptRow(label: 'Vehicle', value: 'Taxi (2-A34567)'),
                  const Divider(height: 48),
                  _ReceiptRow(label: 'Subtotal', value: '14.50 ETB'),
                  _ReceiptRow(label: 'Service Fee', value: '0.50 ETB'),
                  const Divider(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Paid with', style: TextStyle(color: AppTheme.textSecondary)),
                      Text('WuloPay Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download PDF'),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
