import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: AppTheme.surfaceColor, child: Icon(Icons.receipt_long_rounded, size: 40, color: AppTheme.primaryColor)),
            const SizedBox(height: 16),
            const Text('25.00 ETB', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Payment Successful', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _DetailTile(label: 'To', value: 'Bole Taxi (2-A34567)'),
            _DetailTile(label: 'From', value: 'Samuel A. (Wallet)'),
            _DetailTile(label: 'Date', value: 'Jan 24, 2024'),
            _DetailTile(label: 'Time', value: '10:30 AM'),
            _DetailTile(label: 'Transaction ID', value: '#TXN123456789'),
            const Divider(height: 48),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Fare payment for Megenagna to Bole route.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Receipt'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  const _DetailTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainManager.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
