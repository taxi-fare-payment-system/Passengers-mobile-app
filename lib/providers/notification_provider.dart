import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

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
}
