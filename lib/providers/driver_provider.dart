import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverProvider with ChangeNotifier {
  Map<String, dynamic>? _currentDriverProfile;
  bool _isLoading = false;
  final Map<String, Map<String, dynamic>> _publicUserCache = {};

  Map<String, dynamic>? get currentDriverProfile => _currentDriverProfile;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    if (_publicUserCache.containsKey(userId)) {
      return _publicUserCache[userId];
    }

    try {
      final response = await ApiService.get('/api/v1/auth/users/$userId/public');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _publicUserCache[userId] = data;
        return data;
      }
    } catch (e) {
      print('Driver Debug: Error fetching public profile: $e');
    }
    return null;
  }

  Future<void> fetchDriverProfile(String driverId, String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/auth/drivers/$driverId/profile', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        _currentDriverProfile = jsonDecode(response.body);
      } else {
        print('Driver Debug: Failed to fetch profile status ${response.statusCode}');
      }
    } catch (e) {
      print('Driver Debug: Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitDriverReview({
    required String driverId,
    required double rating,
    required String message,
    required String token,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/v1/auth/drivers/$driverId/reviews',
        {
          'rating': rating,
          'message': message,
        },
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['reviews'] != null && _currentDriverProfile != null) {
          _currentDriverProfile!['reviews'] = data['reviews'];
          notifyListeners();
        }
      } else {
        throw Exception('Failed to submit review: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
