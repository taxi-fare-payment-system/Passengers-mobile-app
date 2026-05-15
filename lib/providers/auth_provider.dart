import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isVerified => _user?['is_verified'] ?? false;
  
  Future<void> register({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    final response = await ApiService.post('/api/v1/auth/register', {
      'phone': phone,
      'password': password,
      'display_name': displayName,
      'role': 'passenger',
    });

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  Future<void> sendOTP(String phone) async {
    final response = await ApiService.post('/api/v1/messaging/otp/send', {
      'phone': phone,
      'recipient': phone,
      'type': 'sms',
    });
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> verifyOTP(String phone, String code) async {
    final response = await ApiService.post('/api/v1/auth/verify-phone', {
      'phone': phone,
      'code': code,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
      final response = await ApiService.get('/api/v1/auth/me', token: _token);
      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
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
      '/api/v1/auth/password',
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
