import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: const Text('My Wallet', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${wallet.balance ?? '0.00'} ETB',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (wallet.isLoading && wallet.transactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (wallet.transactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No transactions yet')))
            else
              ...wallet.transactions.take(5).map((tx) {
                final isExpense = tx['sender_wallet_id'] == wallet.walletId || tx['reason'] == 'fare';
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
                      Icon(
                        isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isExpense ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tx['reason'] == 'fare' ? 'Taxi Fare' : 'Top-up',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
