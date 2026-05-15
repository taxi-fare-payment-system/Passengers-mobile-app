import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  List<dynamic> _userDocuments = [];
  bool _isLoading = false;

  List<dynamic> get userDocuments => _userDocuments;
  bool get isLoading => _isLoading;

  Future<void> fetchUserDocuments(String userId, String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/api/v1/documents/user/$userId',
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        _userDocuments = jsonDecode(response.body);
      }
    } catch (e) {
      print('Document Debug: Fetch failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String userId,
    required String documentType,
    required File file,
    required String token,
    Map<String, String>? headers,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/v1/documents/upload'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        ...?headers,
      });

      request.fields['user_id'] = userId;
      request.fields['document_type'] = documentType;
      
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        await fetchUserDocuments(userId, token, headers: headers);
        return data;
      } else {
        final error = jsonDecode(responseData)['error'] ?? 'Upload failed';
        throw Exception(error);
      }
    } catch (e) {
      print('Document Debug: Upload failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
