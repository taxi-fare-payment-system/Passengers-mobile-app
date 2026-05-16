import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            Text('welcome_back'.tr(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
            const SizedBox(height: 8),
            Text('sign_in_passenger'.tr(), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 60),
            
            // Immersive Inputs
            Text('phone_number'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
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
                    decoration: InputDecoration(
                      hintText: '91 234 5678',
                      fillColor: theme.cardColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('password'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              style: const TextStyle(fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '••••••••',
                fillColor: theme.cardColor,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.hintColor),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordDialog(),
                child: Text('forgot_password'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentColor)),
              ),
            ),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : Text('login'.tr().toUpperCase()),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: RichText(
                  text: TextSpan(
                    text: '${'new_here'.tr()} ',
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'create_account'.tr(),
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

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || password.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().login('0$phone', password);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController forgotPhoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('reset_password'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('reset_password_desc'.tr(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: forgotPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '91 234 5678', prefixText: '+251 '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              final phone = forgotPhoneController.text.trim();
              if (phone.isEmpty) return;
              try {
                await context.read<AuthProvider>().resetPassword('0$phone');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('reset_instructions_sent'.tr())));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
            child: Text('send'.tr()),
          ),
        ],
      ),
    );
  }
}
