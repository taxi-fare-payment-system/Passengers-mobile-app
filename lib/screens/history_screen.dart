import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/wallet_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('history'.tr(), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'trips'.tr()),
              Tab(text: 'payments'.tr()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TripsList(),
            _PaymentsList(),
          ],
        ),
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  const _TripsList();

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final tripFares = wallet.transactions.where((tx) => tx['reason'] == 'fare' || tx['type'] == 'fare_payment').toList();

    if (wallet.isLoading && tripFares.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tripFares.isEmpty) {
      return Center(child: Text('no_trips_found'.tr()));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: tripFares.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tx = tripFares[index];
        final DateTime dt = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        
        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/trip-details', arguments: tx['metadata']?['trip_id']),
          child: _HistoryItem(
            icon: Icons.directions_car_rounded,
            title: tx['metadata']?['route_name'] ?? 'taxi_ride'.tr(),
            date: DateFormat('dd MMM yyyy').format(dt),
            time: DateFormat('hh:mm a').format(dt),
            amount: '${tx['amount']} ETB',
            status: tx['status'] == 'completed' || tx['status'] == 'success' ? 'completed'.tr() : 'pending'.tr(),
          ),
        );
      },
    );
  }
}

class _PaymentsList extends StatelessWidget {
  const _PaymentsList();

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final transactions = wallet.transactions;

    if (wallet.isLoading && transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(child: Text('no_payments_found'.tr()));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final DateTime dt = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        final isCredit = tx['type'] == 'topup' || tx['type'] == 'transfer_in';

        return _HistoryItem(
          icon: isCredit ? Icons.account_balance_wallet_rounded : Icons.payments_rounded,
          title: tx['reason'] ?? (isCredit ? 'wallet_top_up'.tr() : 'payment'.tr()),
          date: DateFormat('dd MMM yyyy').format(dt),
          time: DateFormat('hh:mm a').format(dt),
          amount: '${tx['amount']} ${'currency'.tr()}',
          status: tx['status'] == 'completed' || tx['status'] == 'success' ? 'successful'.tr() : 'pending'.tr(),
          isCredit: isCredit,
        );
      },
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String time;
  final String amount;
  final String status;
  final bool isCredit;

  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
    required this.status,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status == 'completed'.tr() || status == 'successful'.tr();
    
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$date • $time', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : ""}$amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCredit ? Colors.green : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCompleted ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
