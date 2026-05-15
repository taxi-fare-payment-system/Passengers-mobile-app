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
      print('Auth Debug: Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      
      _token = data['token'] ?? body['token'];
      _user = data['user'] ?? (data.containsKey('phone') || data.containsKey('display_name') ? data : null);
      
      print('Auth Debug: Extracted User: $_user');
      
      if (_token != null) {
        await _storage.write(key: 'token', value: _token);
        notifyListeners();
      }
    } else {
      print('Auth Debug: Error response: ${response.body}');
      throw Exception(jsonDecode(response.body)['message'] ?? 'Verification failed');
    }
  }

  Future<void> login(String phone, String password) async {
    final response = await ApiService.post('/api/v1/auth/login', {
      'phone': phone,
      'password': password,
    });

    if (response.statusCode == 200) {
      print('Auth Debug (login): Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      
      _token = data['token'] ?? body['token'];
      _user = data['user'] ?? (data.containsKey('phone') || data.containsKey('display_name') ? data : null);
      
      if (_token != null) {
        await _storage.write(key: 'token', value: _token);
        notifyListeners();
      }
    } else {
      print('Auth Debug (login): Error response: ${response.body}');
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
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
        print('Auth Debug (me): Response body: ${response.body}');
        final body = jsonDecode(response.body);
        _user = (body is Map && body.containsKey('data')) ? body['data'] : body;
        // If there's a nested 'user' object, use it
        if (_user != null && _user!.containsKey('user')) {
          _user = _user!['user'];
        }
        print('Auth Debug (me): Extracted User: $_user');
        notifyListeners();
      } else {
        print('Auth Debug (me): Error response: ${response.body}');
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
