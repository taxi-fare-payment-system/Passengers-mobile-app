import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  Future<void> uploadDocument({
    required String userId,
    required String userRole,
    required String documentType,
    required File file,
    required String token,
  }) async {
    _isUploading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/v1/documents/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['user_id'] = userId;
      request.fields['user_role'] = userRole;
      request.fields['document_type'] = documentType;
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(response.body ?? 'Upload failed');
      }
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
