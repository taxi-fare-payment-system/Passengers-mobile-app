import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String? _status;
  String _sort = 'created_at';

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter by Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['succeeded', 'failed', 'pending'].map((s) {
                      final isSelected = _status == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _status = val ? s : null);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: _sort,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'created_at', child: Text('Date')),
                      DropdownMenuItem(value: 'amount', child: Text('Amount')),
                    ],
                    onChanged: (val) {
                      setState(() => _sort = val!);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        context.read<WalletProvider>().fetchTransactions(
                          auth.user?['id'].toString() ?? '', 
                          auth.token!,
                          status: _status,
                          sort: _sort,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<WalletProvider>().fetchTransactions(auth.user?['id'].toString() ?? '', auth.token!);
    });
  }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.black),
              onPressed: () => _showFilterSheet(context),
            ),
          ],
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
            _TransactionList(filterType: 'fare'),
            _TransactionList(filterType: 'wallet topup'),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final String? filterType;
  const _TransactionList({this.filterType});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final transactions = filterType == null 
        ? wallet.transactions 
        : wallet.transactions.where((tx) => tx['reason'] == filterType).toList();

    if (wallet.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No transactions found', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = tx['reason'] == 'fare';
        final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _HistoryItem(
            title: tx['reason'] == 'fare' ? 'Trip Payment' : 'Wallet Top-up',
            date: DateFormat('MMM dd, yyyy • hh:mm a').format(date),
            amount: '${isExpense ? '-' : '+'}${tx['amount']} ETB',
            isExpense: isExpense,
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transactionId: tx['id'].toString()),
              ),
            ),
          ),
        );
      },
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
