import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
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
      context.read<WalletProvider>().fetchTransactions(userId, auth.token!, headers: auth.headers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_wallet'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppTheme.accentColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supreme Balance Card (Minimalist, No Gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('available_balance'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                      const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.accentColor, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${wallet.balance ?? '0.00'} ETB',
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, color: AppTheme.accentColor, letterSpacing: -1),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_rounded,
                          label: 'top_up'.tr(),
                          onTap: () => Navigator.pushNamed(context, '/top-up'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.send_rounded,
                          label: 'transfer'.tr(),
                          onTap: () => Navigator.pushNamed(context, '/transfer'),
                          isAccent: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('recent_transactions'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/transaction-history'),
                  child: Text('see_all'.tr().toUpperCase(), style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (wallet.isLoading && wallet.transactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.accentColor)))
            else if (wallet.transactions.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('no_transactions_yet'.tr(), style: theme.textTheme.bodyMedium)))
            else
              ...wallet.transactions.take(5).map((tx) => _TransactionTile(tx: tx, walletId: wallet.walletId)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isAccent ? AppTheme.accentColor : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAccent ? AppTheme.accentColor : Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isAccent ? Colors.black : AppTheme.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: TextStyle(color: isAccent ? Colors.black : Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic tx;
  final String? walletId;

  const _TransactionTile({required this.tx, this.walletId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = (tx['reason'] ?? '').toString().toLowerCase();
    final isTopUp = reason.contains('topup') || reason.contains('top up');
    final isExpense = !isTopUp && (tx['sender_wallet_id'] == walletId || tx['reason'] == 'fare');
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.call_made_rounded : Icons.call_received_rounded,
              color: isExpense ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    final r = (tx['reason'] ?? '').toString().toLowerCase();
                    final m = (tx['message'] ?? '').toString().toLowerCase();
                    if (r == 'fare' || m.contains('fare')) return 'taxi_fare'.tr();
                    if (r == 'transfer' || m.contains('transfer')) return m.contains('p2p') ? 'p2p_transfer'.tr() : 'transfer'.tr();
                    if (r.contains('topup') || r.contains('top up')) return 'wallet_top_up'.tr();
                    return tx['reason']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'transaction'.tr();
                  }(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(DateTime.parse(tx['created_at'])),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isExpense ? theme.textTheme.bodyLarge?.color : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
