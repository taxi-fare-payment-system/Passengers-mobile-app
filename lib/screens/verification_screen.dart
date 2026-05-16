import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String _documentType = 'national_id';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDocs();
    });
  }

  void _fetchDocs() {
    final auth = context.read<AuthProvider>();
    final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString();
    if (userId != null) {
      context.read<DocumentProvider>().fetchUserDocuments(userId, auth.token!, headers: auth.headers);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) setState(() => _selectedFile = File(image.path));
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    final auth = context.read<AuthProvider>();
    final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString();
    if (userId == null) return;

    try {
      await context.read<DocumentProvider>().uploadDocument(
        userId: userId, documentType: _documentType, file: _selectedFile!, token: auth.token!, headers: auth.headers,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('doc_uploaded_success_msg'.tr()), backgroundColor: Colors.green));
        setState(() => _selectedFile = null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'upload_failed'.tr()}: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('account_verification'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('upload_identity'.tr(), style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('verify_account_desc'.tr(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            
            Text('document_type'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _documentType,
                  isExpanded: true,
                  dropdownColor: theme.cardColor,
                  onChanged: (val) => setState(() => _documentType = val!),
                  items: [
                    DropdownMenuItem(value: 'national_id', child: Text('national_id'.tr(), style: const TextStyle(fontWeight: FontWeight.w800))),
                    DropdownMenuItem(value: 'license', child: Text('driver_license'.tr(), style: const TextStyle(fontWeight: FontWeight.w800))),
                    DropdownMenuItem(value: 'profile_photo', child: Text('profile_photo'.tr(), style: const TextStyle(fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            InkWell(
              onTap: () => _showPickerOptions(),
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.2), width: 2),
                ),
                child: _selectedFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_rounded, size: 64, color: AppTheme.accentColor),
                        const SizedBox(height: 16),
                        Text('tap_take_photo'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.file(_selectedFile!, fit: BoxFit.cover),
                    ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (_selectedFile != null)
              ElevatedButton(
                onPressed: docProvider.isLoading ? null : _upload,
                child: docProvider.isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                  : Text('upload_document'.tr().toUpperCase()),
              ),
            
            const SizedBox(height: 60),
            Text('my_documents'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 24),
            
            if (docProvider.isLoading && docProvider.userDocuments.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
            else if (docProvider.userDocuments.isEmpty)
              Center(child: Text('no_docs_uploaded_yet'.tr(), style: theme.textTheme.bodyMedium))
            else
              ...docProvider.userDocuments.map((doc) => _buildDocItem(doc, theme)),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.accentColor),
                title: Text('take_photo'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentColor),
                title: Text('choose_from_gallery'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocItem(dynamic doc, ThemeData theme) {
    final status = doc['status']?.toString().toLowerCase() ?? 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    final color = isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isApproved ? Icons.check_rounded : (isRejected ? Icons.close_rounded : Icons.access_time_rounded), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['document_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'DOCUMENT',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  '${'uploaded_on'.tr()} ${doc['created_at']?.toString().split('T').first ?? 'N/A'}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}
