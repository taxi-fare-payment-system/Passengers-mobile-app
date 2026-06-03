import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/app_modals.dart';
import '../providers/document_provider.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile_setup'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('upload_profile_photo'.tr(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 48),
            
            _ProfileInputField(label: 'full_name'.tr(), hint: 'full_name_hint'.tr()),
            const SizedBox(height: 20),
            _ProfileInputField(label: 'email_address'.tr(), hint: 'email_hint'.tr()),
            const SizedBox(height: 20),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('default_payment_method'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  hint: Text('select_method'.tr()),
                  items: ['WuloPay Wallet', 'Telebirr', 'CBE Birr', 'Card'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {},
                ),
              ],
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
              child: Text('save_continue'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('change_password'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('security_instructions'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),
            _ProfileInputField(label: 'current_password'.tr(), hint: '••••••••', controller: _currentPasswordController, obscureText: true),
            const SizedBox(height: 20),
            _ProfileInputField(label: 'new_password'.tr(), hint: '••••••••', controller: _newPasswordController, obscureText: true),
            const SizedBox(height: 20),
            _ProfileInputField(label: 'confirm_password'.tr(), hint: '••••••••', controller: _confirmPasswordController, obscureText: true),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  if (_newPasswordController.text != _confirmPasswordController.text) {
                    AppModals.showError(context, 'passwords_do_not_match'.tr());
                    return;
                  }
                  try {
                    await auth.changePassword(_currentPasswordController.text, _newPasswordController.text);
                    if (mounted) {
                      AppModals.showSuccess(context, 'password_updated_success'.tr());
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) AppModals.showException(context, e);
                  }
                },
                child: auth.isLoading 
                  ? const CircularProgressIndicator(color: AppTheme.accentColor)
                  : Text('update_password'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final bool readOnly;
  final TextEditingController? controller;
  final bool obscureText;

  const _ProfileInputField({
    required this.label, 
    this.hint, 
    this.initialValue, 
    this.readOnly = false,
    this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}
