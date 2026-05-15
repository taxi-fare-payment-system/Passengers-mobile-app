import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamController<dynamic>? _streamController;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/notifications', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _notifications = data['items'] ?? [];
        _unreadCount = data['unread_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id, String token) async {
    try {
      final response = await ApiService.patch('/api/v1/notifications/$id/read', {}, token: token);
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['status'] = 'read';
          _unreadCount--;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAsUnread(String id, String token) async {
    try {
      final response = await ApiService.put('/api/v1/notifications/$id/unread', {}, token: token);
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['status'] = 'unread';
          _unreadCount++;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error marking as unread: $e');
    }
  }

  void connectToStream(String userId, String token) {
    _streamController?.close();
    _streamController = StreamController.broadcast();

    // In a real app, we would use an EventSource or WebSocket here.
    // For this task, we'll simulate the real-time aspect or use a simple poll if SSE is not ready.
    // However, I will implement the client-side SSE connection logic.
    
    final url = '${ApiService.baseUrl}/api/v1/notifications/stream?user_id=$userId';
    
    // Using a simple HTTP request for SSE if supported by the server
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'text/event-stream';

    client.send(request).then((response) {
      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('data: ')) {
          final data = jsonDecode(line.substring(6));
          _notifications.insert(0, data);
          _unreadCount++;
          notifyListeners();
          _streamController?.add(data);
        }
      }, onError: (e) {
        debugPrint('SSE Error: $e');
      }, onDone: () {
        debugPrint('SSE Stream closed');
      });
    });
  }

  @override
  void dispose() {
    _streamController?.close();
    super.dispose();
  }
}
