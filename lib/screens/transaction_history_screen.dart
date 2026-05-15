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
        context.read<TripProvider>().fetchTripHistory(auth.token!, headers: auth.headers);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('transactions'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'all'.tr()),
              Tab(text: 'payments'.tr()),
              Tab(text: 'top_ups'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, wallet.transactions, isAll: true),
            _buildList(context, context.watch<TripProvider>().tripHistory, isTrip: true),
            _buildList(context, wallet.transactions.where((tx) => tx['reason'] == 'topup' || tx['reason'] == 'wallet topup').toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> transactions, {bool isTrip = false, bool isAll = false}) {
    final wallet = context.watch<WalletProvider>();
    final trip = context.watch<TripProvider>();
    
    if (wallet.isLoading || trip.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isTrip ? Icons.directions_car_rounded : Icons.history_rounded, size: 48, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(isTrip ? 'no_rides_found'.tr() : 'no_transactions_found'.tr(), style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = isTrip || tx['reason'] == 'fare';
        final amount = double.tryParse((isTrip ? tx['totalFare'] : tx['amount'])?.toString() ?? '0') ?? 0;
        final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTrip ? Icons.directions_car_rounded : (isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
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
                      isTrip ? '${tx['startLocation']} → ${tx['endLocation']}' : (tx['reason'] == 'fare' ? 'taxi_fare'.tr() : 'wallet_top_up'.tr()),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(date),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)} ETB',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isExpense ? AppTheme.textPrimary : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
