import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Transaction Detail', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: Colors.black)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('15.00 ETB', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                  _DetailRow(label: 'To', value: 'Bole Taxi (2-A34567)'),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'From', value: 'Samuel A. (Wallet)'),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Date', value: '24 Jan 2024'),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Time', value: '10:35 AM'),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Transaction ID', value: '#TXN987654321'),
                  const Divider(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      const Text('15.00 ETB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
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
