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
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;

    final auth = context.read<AuthProvider>();
    final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString();
    if (userId == null) return;

    try {
      await context.read<DocumentProvider>().uploadDocument(
        userId: userId,
        documentType: _documentType,
        file: _selectedFile!,
        token: auth.token!,
        headers: auth.headers,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('doc_uploaded_success_msg'.tr()), backgroundColor: Colors.green),
        );
        setState(() {
          _selectedFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'upload_failed'.tr()}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('account_verification'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'upload_identity'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'verify_account_desc'.tr(),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // Document Type Selector
            Text('document_type'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _documentType,
                  isExpanded: true,
                  onChanged: (val) => setState(() => _documentType = val!),
                  items: [
                    DropdownMenuItem(value: 'national_id', child: Text('national_id'.tr())),
                    DropdownMenuItem(value: 'license', child: Text('driver_license'.tr())),
                    DropdownMenuItem(value: 'profile_photo', child: Text('profile_photo'.tr())),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Image Picker Area
            InkWell(
              onTap: () => _showPickerOptions(),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 2),
                ),
                child: _selectedFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, size: 48, color: AppTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('tap_take_photo'.tr(), style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(_selectedFile!, fit: BoxFit.cover),
                    ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (_selectedFile != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: docProvider.isLoading ? null : _upload,
                  child: docProvider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('upload_document'.tr()),
                ),
              ),
            
            const SizedBox(height: 48),
            Text('my_documents'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            
            if (docProvider.isLoading && docProvider.userDocuments.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (docProvider.userDocuments.isEmpty)
              Center(child: Text('no_docs_uploaded_yet'.tr()))
            else
              ...docProvider.userDocuments.map((doc) => _buildDocItem(doc)),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('take_photo'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('choose_from_gallery'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(dynamic doc) {
    final status = doc['status']?.toString().toLowerCase() ?? 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : (isRejected ? Icons.cancel_rounded : Icons.pending_rounded),
            color: isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['document_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'DOCUMENT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${'uploaded_on'.tr()} ${doc['created_at']?.toString().split('T').first ?? 'N/A'}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
