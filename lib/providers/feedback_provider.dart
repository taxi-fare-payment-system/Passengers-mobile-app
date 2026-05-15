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
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // Assuming Trip Service handles feedback as per common patterns
      final response = await ApiService.post(
        '/api/v1/trips/$tripId/feedback',
        {
          'rating': rating,
          'tags': tags,
          'comment': comment,
        },
        token: token,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit feedback');
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
