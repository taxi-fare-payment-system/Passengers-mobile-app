import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('profile_setup'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    _nameController.text = user?['display_name'] ?? user?['name'] ?? '';
    _emailController.text = user?['email'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final docProvider = context.watch<DocumentProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('edit_profile'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=passenger'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            _ProfileInputField(label: 'full_name'.tr(), controller: _nameController),
            const SizedBox(height: 20),
            _ProfileInputField(label: 'email_address'.tr(), controller: _emailController),
            const SizedBox(height: 20),
            _ProfileInputField(label: 'phone_number'.tr(), initialValue: user?['phone'] ?? user?['phone_number'] ?? '+251 900 000 000', readOnly: true),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 32),
            Text('change_password'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ProfileInputField(label: 'current_password'.tr(), hint: '••••••••', controller: _currentPasswordController, obscureText: true),
            const SizedBox(height: 16),
            _ProfileInputField(label: 'new_password'.tr(), hint: '••••••••', controller: _newPasswordController, obscureText: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await auth.changePassword(_currentPasswordController.text, _newPasswordController.text);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('password_updated_success'.tr())));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: Text('update_password'.tr()),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 32),
            Text('identity_verification'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('upload_id_instruction'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: _selectedFile == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_rounded, color: AppTheme.textSecondary, size: 32),
                        SizedBox(height: 8),
                        Text('click_to_select_doc'.tr(), style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_selectedFile!, fit: BoxFit.cover),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: docProvider.isLoading ? null : () async {
                    try {
                      await docProvider.uploadDocument(
                        userId: user?['id']?.toString() ?? '',
                        documentType: 'national_id',
                        file: _selectedFile!,
                        token: auth.token!,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('doc_uploaded_success'.tr())));
                        setState(() => _selectedFile = null);
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: docProvider.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('upload_document'.tr()),
                ),
              ),
            
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: auth.isLoading ? null : () async {
                try {
                  await auth.updateProfile(
                    displayName: _nameController.text,
                    email: _emailController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_updated_success'.tr())));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: auth.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('save_changes'.tr()),
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
