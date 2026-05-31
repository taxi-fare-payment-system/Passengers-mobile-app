import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _storedPhone;
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isVerified => _user?['is_verified'] ?? false;
  bool get isLoading => _isLoading;
  String? get storedPhone => _storedPhone;
  
  Map<String, String> get headers {
    final Map<String, String> h = {};
    var userId = (_user?['id'] ?? _user?['user_id'] ?? _user?['uid'] ?? _user?['_id'])?.toString();
    if (userId == null && _user?['user'] != null) {
      final nested = _user?['user'];
      if (nested is Map) {
        userId = (nested['id'] ?? nested['user_id'] ?? nested['uid'] ?? nested['_id'])?.toString();
      }
    }
    if (userId != null) h['X-User-ID'] = userId;
    
    var role = _user?['role']?.toString();
    if (role == null && _user?['user'] != null) {
      final nested = _user?['user'];
      if (nested is Map) {
        role = nested['role']?.toString();
      }
    }
    if (role != null) h['X-User-Role'] = role;
    return h;
  }
  
  Future<void> register({
    required String phone,
    required String password,
    required String displayName,
    String? subCityId,
  }) async {
    final response = await ApiService.post('/api/v1/auth/register', {
      'phone': phone,
      'password': password,
      'display_name': displayName,
      'role': 'passenger',
      if (subCityId != null) 'sub_city_id': int.tryParse(subCityId) ?? subCityId,
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
      'role': 'passenger',
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
        final userPhone = _user?['phone'] ?? phone;
        await _storage.write(key: 'phone', value: userPhone);
        _storedPhone = userPhone;
        notifyListeners();
      }
    } else {
      print('Auth Debug: Error response: ${response.body}');
      throw Exception(jsonDecode(response.body)['message'] ?? 'Verification failed');
    }
  }

  Future<void> verifyOtpEndpoint(String phone, String code) async {
    final response = await ApiService.post('/api/v1/auth/verify-otp', {
      'phone': phone,
      'role': 'passenger',
      'code': code,
    });

    if (response.statusCode == 200) {
      print('Auth Debug: Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      
      _token = data['token'] ?? body['token'];
      _user = data['user'] ?? (data.containsKey('phone') || data.containsKey('display_name') ? data : null);
      
      if (_token != null) {
        await _storage.write(key: 'token', value: _token);
        final userPhone = _user?['phone'] ?? phone;
        await _storage.write(key: 'phone', value: userPhone);
        _storedPhone = userPhone;
        notifyListeners();
      }
    } else {
      print('Auth Debug: Error response: ${response.body}');
      throw Exception(jsonDecode(response.body)['message'] ?? 'Verification failed');
    }
  }

  List<dynamic> _subCities = [];
  List<dynamic> get subCities => _subCities;

  Future<void> fetchSubCities() async {
    try {
      final response = await ApiService.get('/api/v1/auth/subcities');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _subCities = data is List ? data : (data['items'] ?? data['data'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      print('Auth Debug: Fetch sub-cities failed: $e');
    }
  }

  Future<void> resetPassword(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/v1/auth/forgot-password', {
        'phone': phone,
        'role': 'passenger',
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body)['message'] ?? 'Reset failed';
        throw Exception(error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmPasswordReset(String phone, String code, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/v1/auth/reset-password', {
        'phone': phone,
        'role': 'passenger',
        'code': code,
        'new_password': newPassword,
      });
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['message'] ?? 'Password reset failed';
        throw Exception(error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String phone, String password) async {
    final response = await ApiService.post('/api/v1/auth/login', {
      'phone': phone,
      'password': password,
      'role': 'passenger',
    });

    if (response.statusCode == 200) {
      print('Auth Debug (login): Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      
      _token = data['token'] ?? body['token'];
      _user = data['user'] ?? (data.containsKey('phone') || data.containsKey('display_name') ? data : null);
      
      if (_token != null) {
        await _storage.write(key: 'token', value: _token);
        final userPhone = _user?['phone'] ?? phone;
        await _storage.write(key: 'phone', value: userPhone);
        await _storage.write(key: 'password', value: password);
        _storedPhone = userPhone;
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
    await _storage.delete(key: 'password');
    notifyListeners();
  }

  Future<bool> hasStoredCredentials() async {
    final phone = await _storage.read(key: 'phone');
    final password = await _storage.read(key: 'password');
    return phone != null && password != null;
  }

  Future<void> biometricLogin() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!isAvailable) throw Exception('Biometric authentication is not supported on this device');

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login securely',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (didAuthenticate) {
        final phone = await _storage.read(key: 'phone');
        final password = await _storage.read(key: 'password');
        
        if (phone != null && password != null) {
          await login(phone, password);
        } else {
          throw Exception('No saved credentials found. Please login normally first.');
        }
      } else {
        throw Exception('Biometric authentication failed');
      }
    } catch (e) {
      print('Auth Debug: Biometric login error: $e');
      rethrow;
    }
  }

  Future<void> tryAutoLogin() async {
    _token = await _storage.read(key: 'token');
    _storedPhone = await _storage.read(key: 'phone');
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

  Future<void> updateProfile({required String displayName, String? email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.patch(
        '/api/v1/auth/profile',
        {
          'display_name': displayName,
          if (email != null) 'email': email,
        },
        token: _token,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
        final updatedUser = data['user'] ?? (data.containsKey('display_name') ? data : null);
        if (updatedUser != null) {
          _user = {...?_user, ...updatedUser};
        }
        notifyListeners();
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update profile');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences({
    String? language,
    bool? pushEnabled,
    bool? biometricEnabled,
  }) async {
    final Map<String, dynamic> data = {};
    if (language != null) data['language'] = language;
    if (pushEnabled != null) data['push_enabled'] = pushEnabled;
    if (biometricEnabled != null) data['biometric_enabled'] = biometricEnabled;

    if (data.isEmpty) return;

    try {
      final response = await ApiService.patch(
        '/api/v1/auth/preferences',
        data,
        token: _token,
      );

      if (response.statusCode == 200) {
        if (_user != null) {
          _user = {..._user!, ...data};
          notifyListeners();
        }
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update preferences');
      }
    } catch (e) {
      print('Auth Debug: Update preferences failed: $e');
      rethrow;
    }
  }
}
