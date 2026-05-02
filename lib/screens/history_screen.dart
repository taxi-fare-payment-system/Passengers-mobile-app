import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Trips'),
              Tab(text: 'Payments'),
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
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 10,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _HistoryItem(
          icon: Icons.directions_car_rounded,
          title: 'Megenagna to Stadium',
          date: '24 Jan 2024',
          time: '10:30 AM',
          amount: '15.00 ETB',
          status: 'Completed',
        );
      },
    );
  }
}

class _PaymentsList extends StatelessWidget {
  const _PaymentsList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _HistoryItem(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Wallet Top-up',
          date: '23 Jan 2024',
          time: '04:15 PM',
          amount: '500.00 ETB',
          status: 'Successful',
          isCredit: true,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$date • $time', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                  color: isCredit ? Colors.green : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: status == 'Completed' || status == 'Successful' ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
