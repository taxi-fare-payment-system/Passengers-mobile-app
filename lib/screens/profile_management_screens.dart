import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: const Text('Profile Setup', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            const Text('Upload Profile Photo', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 48),
            
            const _ProfileInputField(label: 'Full Name', hint: 'e.g. Samuel Abera'),
            const SizedBox(height: 20),
            const _ProfileInputField(label: 'Email Address', hint: 'e.g. samuel@example.com'),
            const SizedBox(height: 20),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Default Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  hint: const Text('Select Method'),
                  items: ['WuloPay Wallet', 'Telebirr', 'CBE Birr', 'Card'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {},
                ),
              ],
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
              child: const Text('Save & Continue'),
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
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  File? _selectedFile;

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
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            
            _ProfileInputField(label: 'Full Name', initialValue: user?['name'] ?? 'Passenger User'),
            const SizedBox(height: 20),
            _ProfileInputField(label: 'Phone Number', initialValue: user?['phone'] ?? '+251 900 000 000', readOnly: true),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 32),
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ProfileInputField(label: 'Current Password', hint: '••••••••', controller: _currentPasswordController, obscureText: true),
            const SizedBox(height: 16),
            _ProfileInputField(label: 'New Password', hint: '••••••••', controller: _newPasswordController, obscureText: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await auth.changePassword(_currentPasswordController.text, _newPasswordController.text);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Update Password'),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 32),
            const Text('Identity Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Upload a copy of your National ID or Passport to verify your account.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                      children: const [
                        Icon(Icons.upload_file_rounded, color: AppTheme.textSecondary, size: 32),
                        SizedBox(height: 8),
                        Text('Click to select document', style: TextStyle(color: AppTheme.textSecondary)),
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
                  onPressed: docProvider.isUploading ? null : () async {
                    try {
                      await docProvider.uploadDocument(
                        userId: user?['id']?.toString() ?? '',
                        userRole: 'passenger',
                        documentType: 'national_id',
                        file: _selectedFile!,
                        token: auth.token!,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully')));
                        setState(() => _selectedFile = null);
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: docProvider.isUploading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload Document'),
                ),
              ),
            
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save Changes'),
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
