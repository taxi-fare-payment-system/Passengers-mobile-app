import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final auth = context.read<AuthProvider>();
      final wallet = context.read<WalletProvider>();
      final detail = await wallet.fetchTransactionDetail(widget.transactionId, auth.token!);
      if (mounted) setState(() { _detail = detail; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    }

    final tx = _detail!;
    final isExpense = tx['reason'] == 'fare';
    final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('transaction'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(
                isExpense ? Icons.north_east_rounded : Icons.check_circle_rounded, 
                size: 64, 
                color: isExpense ? Colors.red : Colors.green
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isExpense ? 'taxi_fare'.tr() : 'top_up_successful'.tr(), 
              style: TextStyle(color: isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 8),
            Text(
              '${isExpense ? '-' : '+'}${tx['amount']} ${'currency'.tr()}', 
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
            ),
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _DetailRow(label: isExpense ? 'To' : 'From', value: isExpense ? 'Driver' : tx['payment_method'] ?? 'External Provider'),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Reason', value: tx['reason'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Date', value: DateFormat('dd MMM yyyy').format(date)),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Time', value: DateFormat('hh:mm a').format(date)),
                  const SizedBox(height: 16),
                  const Divider(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      Text('${tx['amount']} ${'currency'.tr()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download Receipt'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
