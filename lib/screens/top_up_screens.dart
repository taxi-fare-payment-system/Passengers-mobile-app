import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('top_up_wallet'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immersive Amount Input
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text('enter_amount'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color, letterSpacing: -2),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0.00',
                      suffixText: 'ETB',
                      suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['100', '200', '500', '1000'].map((amt) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('$amt ETB', style: const TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () => setState(() => _amountController.text = amt),
                    backgroundColor: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 48),
            Text('payment_method'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
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
            
            const SizedBox(height: 60),
            
            ElevatedButton(
              onPressed: _handleTopUp,
              child: Text('proceed_to_payment'.tr().toUpperCase()),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTopUp() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('please_enter_amount'.tr())));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('please_enter_valid_amount'.tr())));
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();
      
      final checkoutUrl = await walletProvider.initiateTopup(
        walletId: walletProvider.walletId ?? '',
        amount: amount,
        phone: auth.user?['phone'],
        email: auth.user?['email'],
        token: auth.token!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopUpRedirectScreen(checkoutUrl: checkoutUrl, amount: amount),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : theme.dividerColor.withOpacity(0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.1) : theme.dividerColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.black : AppTheme.accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 16, 
                      color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color
                    )
                  ),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: isSelected ? Colors.black.withOpacity(0.6) : theme.hintColor, 
                      fontSize: 12,
                      fontWeight: FontWeight.w600
                    )
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class TopUpRedirectScreen extends StatefulWidget {
  final String checkoutUrl;
  final double amount;
  const TopUpRedirectScreen({super.key, required this.checkoutUrl, required this.amount});

  @override
  State<TopUpRedirectScreen> createState() => _TopUpRedirectScreenState();
}

class _TopUpRedirectScreenState extends State<TopUpRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _launchAndPoll();
  }

  Future<void> _launchAndPoll() async {
    final url = Uri.parse(widget.checkoutUrl);
    try {
      await launchUrl(
        url,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      
      final auth = context.read<AuthProvider>();
      final wallet = context.read<WalletProvider>();
      
      await wallet.pollBalanceChange(auth.user?['id']?.toString() ?? auth.user?['user_id']?.toString() ?? '', auth.token!);

      if (mounted) {
        if (double.parse(wallet.balance ?? '0') > 0) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TopUpSuccessScreen(amount: widget.amount)),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 80, color: AppTheme.accentColor),
              const SizedBox(height: 32),
              Text('securing_transaction'.tr(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
              const SizedBox(height: 16),
              Text(
                'redirecting_to_payment'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class TopUpSuccessScreen extends StatelessWidget {
  final double amount;
  const TopUpSuccessScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
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
              Text('top_up_successful'.tr(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
              const SizedBox(height: 12),
              Text('wallet_credited_successfully'.tr(), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Text('total_top_up_amount'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text('${amount.toStringAsFixed(2)} ETB', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.accentColor, letterSpacing: -1)),
                    const Divider(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('new_wallet_balance'.tr(), style: theme.textTheme.bodyMedium),
                        Text('${wallet.balance ?? '0.00'} ETB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('back_to_wallet'.tr().toUpperCase()),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: Text('go_to_home'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
