import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_modals.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('WULO PAY', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 4, color: AppTheme.accentColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text('create_account'.tr(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
            const SizedBox(height: 8),
            Text('join_wulo_pay'.tr(), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 48),
            
            _buildLabel(context, 'full_name'.tr()),
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              style: const TextStyle(fontWeight: FontWeight.w800),
              decoration: InputDecoration(hintText: 'full_name_hint'.tr(), fillColor: theme.cardColor),
            ),
            
            const SizedBox(height: 24),
            _buildLabel(context, 'phone_number'.tr()),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: const Text('+251', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isLoading,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    decoration: InputDecoration(hintText: '91 234 5678', fillColor: theme.cardColor),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildLabel(context, 'password'.tr()),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_isLoading,
              style: const TextStyle(fontWeight: FontWeight.w800),
              decoration: InputDecoration(hintText: '••••••••', fillColor: theme.cardColor),
            ),
            

            
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                  : Text('sign_up'.tr().toUpperCase()),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    text: '${'already_have_account'.tr()} ',
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'login'.tr(),
                        style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }



  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || phone.isEmpty || password.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final fullPhone = '0$phone';
      await context.read<AuthProvider>().register(phone: fullPhone, password: password, displayName: name);
      if (mounted) Navigator.pushReplacementNamed(context, '/otp', arguments: {'phone': fullPhone, 'password': password});
    } catch (e) {
      if (mounted) AppModals.showException(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
