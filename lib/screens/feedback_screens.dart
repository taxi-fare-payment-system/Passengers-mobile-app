import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/driver_provider.dart';
import '../utils/app_modals.dart';

class RateTripScreen extends StatefulWidget {
  final String tripId;
  final String? driverId;
  const RateTripScreen({super.key, required this.tripId, this.driverId});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('rate_your_trip'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Spacer(),
            Text(
              'how_was_ride'.tr(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 56,
                  color: index < _rating ? Colors.orange : theme.dividerColor,
                ),
              )),
            ),
            const SizedBox(height: 16),
            if (_rating > 0)
              Text(
                _getRatingText().toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 1.5),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                    child: Text('skip'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating > 0
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackFormScreen(tripId: widget.tripId, driverId: widget.driverId, rating: _rating)))
                      : null,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                    child: Text('continue'.tr().toUpperCase(), style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
}

class FeedbackFormScreen extends StatefulWidget {
  final String tripId;
  final String? driverId;
  final int rating;
  const FeedbackFormScreen({super.key, required this.tripId, this.driverId, required this.rating});

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('write_comment'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'share_experience_hint'.tr(),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: feedbackProvider.isSubmitting
                    ? null
                    : () async {
                        try {
                          if (widget.driverId != null) {
                            await driverProvider.submitDriverReview(
                              driverId: widget.driverId!,
                              rating: widget.rating.toDouble(),
                              message: _commentController.text.isNotEmpty
                                  ? _commentController.text
                                  : 'No comment provided',
                              token: auth.token!,
                              headers: auth.headers,
                            );
                          } else {
                            await feedbackProvider.submitFeedback(
                              tripId: widget.tripId,
                              rating: widget.rating,
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
                            AppModals.showException(context, e);
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
