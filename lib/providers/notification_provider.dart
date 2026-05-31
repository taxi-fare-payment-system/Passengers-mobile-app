import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isPushEnabled = true;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isPushEnabled => _isPushEnabled;

  void togglePushNotifications(bool value) {
    _isPushEnabled = value;
    notifyListeners();
  }

  Future<void> fetchNotifications(String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/api/v1/notifications',
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _notifications = data['items'] ?? [];
        _unreadCount = data['unread_count'] ?? 0;
      }
    } catch (e) {
      print('Notification Debug: Fetch failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.put(
        '/api/v1/notifications/$id/read',
        {},
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['status'] = 'read';
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Notification Debug: Mark as read failed: $e');
    }
  }

  Future<void> markAllAsRead(String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.put(
        '/api/v1/notifications/read-all',
        {},
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        for (var n in _notifications) {
          n['status'] = 'read';
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('Notification Debug: Mark all as read failed: $e');
    }
  }

  Future<void> registerDeviceToken(String fcmToken, String platform, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.post(
        '/api/v1/notifications/register',
        {
          'token': fcmToken,
          'platform': platform,
        },
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Notification Debug: Device token registered successfully: ${response.statusCode} - ${response.body}');
      } else {
        print('Notification Debug: Failed to register device token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Notification Debug: Register device token failed: $e');
    }
  }

  Future<void> unregisterDeviceToken(String fcmToken, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.delete(
        '/api/v1/notifications/register',
        {
          'token': fcmToken,
        },
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Notification Debug: Device token unregistered successfully: ${response.statusCode} - ${response.body}');
      } else {
        print('Notification Debug: Failed to unregister device token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Notification Debug: Unregister device token failed: $e');
    }
  }
}
