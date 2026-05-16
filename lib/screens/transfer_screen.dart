import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('transfer_funds'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('recipient_details'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _recipientController,
                      decoration: InputDecoration(
                        labelText: 'phone_number'.tr(),
                        hintText: '09xxxxxxxx',
                        fillColor: theme.cardColor,
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      validator: (value) => value == null || value.isEmpty ? 'required'.tr() : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.accentColor, size: 28),
                      onPressed: () => _scanRecipientQR(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('amount'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'amount_etb'.tr(),
                  prefixText: 'ETB ',
                  fillColor: theme.cardColor,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'required'.tr();
                  final amt = double.tryParse(value);
                  if (amt == null || amt <= 0) return 'invalid_amount'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text('message_optional'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'whats_this_for'.tr(),
                  fillColor: theme.cardColor,
                ),
                maxLines: 3,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: walletProvider.isTransferring
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            final token = auth.token!;
                            await walletProvider.transferFunds(
                              fromWalletId: walletProvider.walletId!,
                              toPhoneNumber: _recipientController.text.trim(),
                              amount: double.parse(_amountController.text),
                              message: _messageController.text.isNotEmpty ? _messageController.text : null,
                              token: token,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('transfer_successful'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)), 
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                              );
                            }
                          }
                        }
                      },
                child: walletProvider.isTransferring
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                    : Text('send_money'.tr().toUpperCase()),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _scanRecipientQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('scan_recipient_qr'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null) {
                          setState(() => _recipientController.text = code);
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary))
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
