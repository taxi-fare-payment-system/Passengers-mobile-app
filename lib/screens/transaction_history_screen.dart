import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Transaction History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: const BackButton(color: Colors.black),
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Payments'),
              Tab(text: 'Top-ups'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TransactionList(),
            _TransactionList(type: 'Payment'),
            _TransactionList(type: 'Top-up'),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final String? type;
  const _TransactionList({this.type});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('This Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        _HistoryItem(
          title: 'Ride to Stadium',
          date: 'Oct 12, 2023',
          amount: '-15.00 ETB',
          isExpense: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionDetailScreen())),
        ),
        const SizedBox(height: 16),
        _HistoryItem(
          title: 'Telebirr Top-up',
          date: 'Oct 10, 2023',
          amount: '+500.00 ETB',
          isExpense: false,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionDetailScreen())),
        ),
        const SizedBox(height: 32),
        const Text('Last Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        _HistoryItem(
          title: 'Ride to Bole',
          date: 'Sep 28, 2023',
          amount: '-25.00 ETB',
          isExpense: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionDetailScreen())),
        ),
        const SizedBox(height: 16),
        _HistoryItem(
          title: 'CBE Birr Top-up',
          date: 'Sep 25, 2023',
          amount: '+200.00 ETB',
          isExpense: false,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionDetailScreen())),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool isExpense;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isExpense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
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
                isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
                size: 20,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isExpense ? AppTheme.textPrimary : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
