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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('my_wallet'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('available_balance'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${wallet.balance ?? '0.00'} ETB',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/top-up'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text('top_up'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/transfer'),
                    icon: const Icon(Icons.send_rounded),
                    label: Text('transfer'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      foregroundColor: Colors.orange,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('recent_transactions'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (wallet.isLoading && wallet.transactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (wallet.transactions.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('no_transactions_yet'.tr())))
            else
              ...wallet.transactions.take(5).map((tx) {
                final reason = (tx['reason'] ?? '').toString().toLowerCase();
                final isTopUp = reason.contains('topup') || reason.contains('top up');
                final isExpense = !isTopUp && (tx['sender_wallet_id'] == wallet.walletId || tx['reason'] == 'fare');
                final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpense ? Icons.call_made_rounded : Icons.call_received_rounded,
                          color: isExpense ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              () {
                                final reason = (tx['reason'] ?? '').toString().toLowerCase();
                                final message = (tx['message'] ?? '').toString().toLowerCase();
                                
                                if (reason == 'fare' || message.contains('fare')) return 'taxi_fare'.tr();
                                if (reason == 'transfer' || message.contains('transfer')) {
                                  if (message.contains('p2p')) return 'p2p_transfer'.tr();
                                  return 'transfer'.tr();
                                }
                                if (reason.contains('topup') || reason.contains('top up')) return 'wallet_top_up'.tr();
                                
                                return tx['reason']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'transaction'.tr();
                              }(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (tx['created_at'] != null)
                              Text(
                                DateFormat('MMM dd, HH:mm').format(DateTime.parse(tx['created_at'])),
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpense ? AppTheme.textPrimary : Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
