import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const Flutter_secure_storage();
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isVerified => _user?['is_verified'] ?? false;

  Future<void> sendOTP(String phone) async {
    final response = await ApiService.post('/auth/api/v1/auth/send-otp', {'phone': phone});
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> verifyOTP(String phone, String code) async {
    final response = await ApiService.post('/auth/api/v1/auth/verify-otp', {
      'phone': phone,
      'code': code,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      _token = data['token'];
      _user = data['user'];
      await _storage.write(key: 'token', value: _token);
      notifyListeners();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Verification failed');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    _token = await _storage.read(key: 'token');
    if (_token == null) return;

    try {
      final response = await ApiService.get('/auth/api/v1/auth/me', token: _token);
      if (response.statusCode == 200) {
        _user = jsonDecode(response.body)['data'];
        notifyListeners();
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await ApiService.patch(
      '/auth/api/v1/auth/password',
      {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
      token: _token,
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to change password');
    }
  }
}
