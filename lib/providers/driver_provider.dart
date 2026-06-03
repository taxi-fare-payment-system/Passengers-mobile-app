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
        final body = jsonDecode(response.body);
        _currentDriverProfile = (body is Map && body.containsKey('data')) ? body['data'] : body;
        print('Driver Debug: Extracted Driver Profile: $_currentDriverProfile');
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
    String? existingReviewId,
  }) async {
    try {
      // If we have an existing review ID, update it instead of creating a new one
      if (existingReviewId != null && existingReviewId.isNotEmpty) {
        final updateResponse = await ApiService.put(
          '/api/v1/auth/drivers/$driverId/reviews/$existingReviewId',
          {
            'rating': rating,
            'message': message,
          },
          token: token,
          extraHeaders: headers,
        );
        if (updateResponse.statusCode == 200 || updateResponse.statusCode == 201) {
          final data = jsonDecode(updateResponse.body);
          if (data['reviews'] != null && _currentDriverProfile != null) {
            _currentDriverProfile!['reviews'] = data['reviews'];
            notifyListeners();
          }
          return;
        }
        // If update endpoint failed, fall through to try POST
      }

      // Try creating a new review
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
      } else if (response.statusCode == 409 || response.statusCode == 400) {
        // Review already exists — try PUT without ID (some APIs update by driver+user)
        final updateResponse = await ApiService.put(
          '/api/v1/auth/drivers/$driverId/reviews',
          {
            'rating': rating,
            'message': message,
          },
          token: token,
          extraHeaders: headers,
        );
        if (updateResponse.statusCode == 200 || updateResponse.statusCode == 201) {
          final data = jsonDecode(updateResponse.body);
          if (data['reviews'] != null && _currentDriverProfile != null) {
            _currentDriverProfile!['reviews'] = data['reviews'];
            notifyListeners();
          }
        } else {
          throw Exception('Failed to update review: ${updateResponse.body}');
        }
      } else {
        throw Exception('Failed to submit review: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDriverProfileData(String driverId, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.get('/api/v1/auth/drivers/$driverId/profile', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Driver Debug: Error fetching driver profile data: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMyReview(String driverId, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.get(
        '/api/v1/auth/drivers/$driverId/reviews/mine',
        token: token,
        extraHeaders: headers,
      );
      print('Driver Debug (getMyReview): Status = ${response.statusCode}, Body = ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map) {
          if (body['data'] != null) {
            final data = body['data'];
            if (data is Map) {
              if (data['review'] != null) {
                return Map<String, dynamic>.from(data['review'] as Map);
              }
              if (data['driver_id'] != null || data['id'] != null) {
                return Map<String, dynamic>.from(data);
              }
            }
          }
          if (body['review'] != null) {
            return Map<String, dynamic>.from(body['review'] as Map);
          }
        }
      }
    } catch (e) {
      print('Driver Debug: Error fetching my review: $e');
    }
    return null;
  }
}
