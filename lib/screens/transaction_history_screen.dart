import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/trip_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString();
      if (auth.token != null && userId != null) {
        context.read<WalletProvider>().fetchTransactions(userId, auth.token!, headers: auth.headers);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('transactions'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppTheme.accentColor)),
          bottom: TabBar(
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.3) : theme.hintColor.withOpacity(0.5),
            indicatorColor: AppTheme.accentColor,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
            tabs: [
              Tab(text: 'all'.tr().toUpperCase()),
              Tab(text: 'payments'.tr().toUpperCase()),
              Tab(text: 'top_ups'.tr().toUpperCase()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, wallet.transactions, isAll: true),
            _buildList(context, wallet.transactions.where((tx) => tx['reason'] == 'fare' || tx['reason'] == 'fare-payment').toList(), isTrip: true),
            _buildList(context, wallet.transactions.where((tx) => tx['reason'] == 'topup' || tx['reason'] == 'wallet topup').toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> transactions, {bool isTrip = false, bool isAll = false}) {
    final wallet = context.watch<WalletProvider>();
    final trip = context.watch<TripProvider>();
    final theme = Theme.of(context);
    
    if (wallet.isLoading || trip.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isTrip ? Icons.directions_car_rounded : Icons.history_rounded, size: 64, color: theme.dividerColor.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(isTrip ? 'no_rides_found'.tr() : 'no_transactions_found'.tr(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final reason = (tx['reason'] ?? '').toString().toLowerCase();
        final isTopUp = reason.contains('topup') || reason.contains('top up');
        final isExpense = !isTopUp && (isTrip || tx['reason'] == 'fare' || (tx['sender_wallet_id'] == wallet.walletId));
        final amount = double.tryParse((isTrip ? tx['totalFare'] : tx['amount'])?.toString() ?? '0') ?? 0;
        final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();

        return Container(
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
                  isTrip ? Icons.local_taxi_rounded : (isExpense ? Icons.call_made_rounded : Icons.call_received_rounded),
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
                        if (isTrip) return '${tx['startLocation']} → ${tx['endLocation']}';
                        final r = (tx['reason'] ?? '').toString().toLowerCase();
                        final m = (tx['message'] ?? '').toString().toLowerCase();
                        if (r == 'fare' || m.contains('fare')) return 'taxi_fare'.tr();
                        if (r == 'transfer' || m.contains('transfer')) return m.contains('p2p') ? 'p2p_transfer'.tr() : 'transfer'.tr();
                        if (r.contains('topup') || r.contains('top up')) return 'wallet_top_up'.tr();
                        return tx['reason']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'transaction'.tr();
                      }(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(date),
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
      },
    );
  }
}
