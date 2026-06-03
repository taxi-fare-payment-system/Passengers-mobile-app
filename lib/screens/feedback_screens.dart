import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/driver_provider.dart';
import '../utils/app_modals.dart';

// RateTripScreen now redirects directly to FeedbackFormScreen (no intermediate page)
class RateTripScreen extends StatelessWidget {
  final String tripId;
  final String? driverId;
  final String? existingReviewId;
  const RateTripScreen({super.key, required this.tripId, this.driverId, this.existingReviewId});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect — no separate "rate your trip" page needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackFormScreen(
            tripId: tripId,
            driverId: driverId,
            existingReviewId: existingReviewId,
          ),
        ),
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
    );
  }
}

class FeedbackFormScreen extends StatefulWidget {
  final String tripId;
  final String? driverId;
  final String? existingReviewId;

  const FeedbackFormScreen({
    super.key,
    required this.tripId,
    this.driverId,
    this.existingReviewId,
  });

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingText() {
    switch (_rating) {
      case 1: return 'poor'.tr();
      case 2: return 'fair'.tr();
      case 3: return 'good'.tr();
      case 4: return 'very_good'.tr();
      case 5: return 'excellent'.tr();
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = context.watch<FeedbackProvider>();
    final driverProvider = context.watch<DriverProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('add_feedback'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // Star rating
            Text(
              'how_was_ride'.tr(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 52,
                  color: index < _rating ? Colors.orange : theme.dividerColor,
                ),
              )),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _getRatingText().toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                  letterSpacing: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Comment field
            Align(
              alignment: Alignment.centerLeft,
              child: Text('write_comment'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'share_experience_hint'.tr(),
              ),
            ),

            const SizedBox(height: 48),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_rating == 0 || feedbackProvider.isSubmitting)
                    ? null
                    : () async {
                        try {
                          if (widget.driverId != null) {
                            await driverProvider.submitDriverReview(
                              driverId: widget.driverId!,
                              rating: _rating.toDouble(),
                              message: _commentController.text.isNotEmpty
                                  ? _commentController.text
                                  : 'No comment provided',
                              token: auth.token!,
                              headers: auth.headers,
                              existingReviewId: widget.existingReviewId,
                            );
                          } else {
                            await feedbackProvider.submitFeedback(
                              tripId: widget.tripId,
                              rating: _rating,
                              tags: [],
                              comment: _commentController.text,
                              token: auth.token!,
                              headers: auth.headers,
                            );
                          }
                          if (mounted) {
                            AppModals.showSuccess(context, 'feedback_submitted_thanks'.tr());
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        } catch (e) {
                          if (mounted) {
                            AppModals.showError(context, e.toString().replaceAll('Exception: ', ''));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                child: feedbackProvider.isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                    : Text('submit_feedback'.tr().toUpperCase()),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
