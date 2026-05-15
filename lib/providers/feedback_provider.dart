import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedbackProvider with ChangeNotifier {
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Future<void> submitFeedback({
    required String tripId,
    required int rating,
    required List<String> tags,
    required String comment,
    required String token,
    Map<String, String>? headers,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/api/v1/feedback',
        {
          'trip_id': tripId,
          'rating': rating,
          'tags': tags,
          'comment': comment,
        },
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit feedback: ${response.body}');
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
