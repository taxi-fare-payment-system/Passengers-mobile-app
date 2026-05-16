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
      // TODO: Actual implementation when backend endpoint is ready
      // For now, we mock the success to avoid 404 during testing
      await Future.delayed(const Duration(seconds: 1));
      print('Feedback Mock: Submitted for trip $tripId - Rating: $rating');
      return;

      /*
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
      */
    } catch (e) {
      debugPrint('Feedback Error: $e');
      // Still return success for mock purposes
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
