import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/qr_provider.dart';

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('top_up_wallet'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppTheme.accentColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supreme Amount Card
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text('enter_amount'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 48, color: AppTheme.accentColor, letterSpacing: -2),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.2)),
                      suffixText: 'currency'.tr(),
                      suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
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
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _amountController.text = amt),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      ),
                      child: Text('$amt ${'currency'.tr()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 60),
            Text('payment_method'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 24),
            
            _PaymentMethodTile(
              title: 'Telebirr',
              subtitle: 'telebirr_desc'.tr(),
              icon: Icons.account_balance_wallet_rounded,
              isSelected: _selectedMethod == 'Telebirr',
              onTap: () => setState(() => _selectedMethod = 'Telebirr'),
            ),
            const SizedBox(height: 16),
            _PaymentMethodTile(
              title: 'CBE Birr',
              subtitle: 'cbebirr_desc'.tr(),
              icon: Icons.account_balance_rounded,
              isSelected: _selectedMethod == 'CBE Birr',
              onTap: () => setState(() => _selectedMethod = 'CBE Birr'),
            ),
            const SizedBox(height: 16),
            _PaymentMethodTile(
              title: 'Card',
              subtitle: 'card_desc'.tr(),
              icon: Icons.credit_card_rounded,
              isSelected: _selectedMethod == 'Card',
              onTap: () => setState(() => _selectedMethod = 'Card'),
            ),
            
            const SizedBox(height: 80),
            
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
        padding: const EdgeInsets.all(24),
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
                    title.toUpperCase(), 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 14, 
                      letterSpacing: 1,
                      color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: isSelected ? Colors.black.withOpacity(0.6) : theme.hintColor, 
                      fontSize: 11,
                      fontWeight: FontWeight.w700
                    )
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
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
        // Trigger notification and transaction refresh
        final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString() ?? '';
        if (userId.isNotEmpty) {
          context.read<NotificationProvider>().fetchNotifications(auth.token!, headers: auth.headers);
          wallet.fetchTransactions(userId, auth.token!);
        }

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 80, color: AppTheme.accentColor),
              const SizedBox(height: 32),
              Text('securing_transaction'.tr().toUpperCase(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 24)),
              const SizedBox(height: 16),
              Text(
                'redirecting_to_payment'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
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
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
              Text('top_up_successful'.tr().toUpperCase(), textAlign: TextAlign.center, style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
              const SizedBox(height: 12),
              Text('wallet_credited_successfully'.tr(), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 60),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Text('total_top_up_amount'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                    const SizedBox(height: 12),
                    Text('${amount.toStringAsFixed(2)} ${'currency'.tr()}', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, color: AppTheme.accentColor, letterSpacing: -1)),
                    const SizedBox(height: 32),
                    Divider(color: theme.dividerColor.withOpacity(0.1)),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('new_wallet_balance'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                        Text('${wallet.balance ?? '0.00'} ${'currency'.tr()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: Text('go_to_home'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accentColor, fontSize: 12, letterSpacing: 1)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
