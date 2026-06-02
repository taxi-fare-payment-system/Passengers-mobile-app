import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('payment_methods'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: theme.iconTheme.color),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('primary_method'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _PaymentMethodItem(
            icon: Icons.account_balance_wallet_rounded,
            title: 'wulopay_wallet'.tr(),
            subtitle: '${'balance'.tr()}: 500 ${'currency'.tr()}',
            isSelected: true,
          ),
          const SizedBox(height: 32),
          Text('other_methods'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _PaymentMethodItem(
            icon: Icons.account_balance_rounded,
            title: 'Telebirr',
            subtitle: 'connected'.tr(),
            isSelected: false,
          ),
          const SizedBox(height: 12),
          _PaymentMethodItem(
            icon: Icons.credit_card_rounded,
            title: 'Mastercard •••• 4567',
            subtitle: '${'expires'.tr()} 05/26',
            isSelected: false,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: Text('add_new_method'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;

  const _PaymentMethodItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor.withOpacity(0.05), width: isSelected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 24),
        ],
      ),
    );
  }
}
