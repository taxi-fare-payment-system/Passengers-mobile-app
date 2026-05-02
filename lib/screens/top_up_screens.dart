import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'Telebirr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: 'ETB',
                suffixStyle: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: ['100', '200', '500', '1000'].map((amt) => ActionChip(
                label: Text('$amt ETB'),
                onPressed: () => setState(() => _amountController.text = amt),
                backgroundColor: AppTheme.surfaceColor,
              )).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _PaymentMethodTile(
              title: 'Telebirr',
              subtitle: 'Pay with your Telebirr account',
              icon: Icons.account_balance_wallet_rounded,
              isSelected: _selectedMethod == 'Telebirr',
              onTap: () => setState(() => _selectedMethod = 'Telebirr'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'CBE Birr',
              subtitle: 'Pay with your CBE Birr account',
              icon: Icons.account_balance_rounded,
              isSelected: _selectedMethod == 'CBE Birr',
              onTap: () => setState(() => _selectedMethod = 'CBE Birr'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard',
              icon: Icons.credit_card_rounded,
              isSelected: _selectedMethod == 'Card',
              onTap: () => setState(() => _selectedMethod = 'Card'),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TopUpRedirectScreen())),
              child: const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class TopUpRedirectScreen extends StatefulWidget {
  const TopUpRedirectScreen({super.key});

  @override
  State<TopUpRedirectScreen> createState() => _TopUpRedirectScreenState();
}

class _TopUpRedirectScreenState extends State<TopUpRedirectScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TopUpSuccessScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainManager.center,
            children: [
              const Icon(Icons.security_rounded, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 32),
              const Text('Securing Transaction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'You are being redirected to your payment provider to complete the transaction.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class TopUpSuccessScreen extends StatelessWidget {
  const TopUpSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainManager.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 100, color: Colors.green),
              const SizedBox(height: 32),
              const Text('Top-Up Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Your wallet has been topped up successfully.', textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Text('New Balance', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('1,540.75 ETB', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Wallet')),
            ],
          ),
        ),
      ),
    );
  }
}
