import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/driver_provider.dart';
import '../utils/app_modals.dart';

/// Single-page rate + review screen.
/// Pass [existingReview] to pre-fill with the user's previous review.
class RateTripScreen extends StatefulWidget {
  final String tripId;
  final String? driverId;
  final Map<String, dynamic>? existingReview;

  const RateTripScreen({
    super.key,
    required this.tripId,
    this.driverId,
    this.existingReview,
  });

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if the user already submitted a review
    if (widget.existingReview != null) {
      final prev = widget.existingReview!;
      _rating = (prev['rating'] as num?)?.round() ?? 0;
      _commentController.text = prev['message']?.toString() ?? prev['comment']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppModals.showError(context, 'please_select_rating'.tr());
      return;
    }
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final driverProvider = context.read<DriverProvider>();
    final feedbackProvider = context.read<FeedbackProvider>();

    try {
      if (widget.driverId != null) {
        final existingId = widget.existingReview?['id']?.toString();
        await driverProvider.submitDriverReview(
          driverId: widget.driverId!,
          rating: _rating.toDouble(),
          message: _commentController.text.isNotEmpty
              ? _commentController.text
              : 'No comment provided',
          token: auth.token!,
          headers: auth.headers,
          existingReviewId: existingId,
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
        setState(() => _isSubmitting = false);
        AppModals.showException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrevious = widget.existingReview != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          hasPrevious ? 'edit_review'.tr() : 'rate_your_trip'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Row(
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
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _rating == 0 ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                  child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                    : Text('submit_feedback'.tr().toUpperCase(), style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Previous review banner ──
            if (hasPrevious) ...[
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 16, color: AppTheme.accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'your_previous_review'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.accentColor, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < (widget.existingReview!['rating'] as num? ?? 0).round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                        size: 20,
                        color: Colors.orange,
                      )),
                    ),
                    if ((widget.existingReview!['message'] ?? widget.existingReview!['comment'])?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.existingReview!['message']?.toString() ?? widget.existingReview!['comment']?.toString() ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Star rating ──
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'how_was_ride'.tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 1.5),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Comment ──
            Text('write_comment'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'share_experience_hint'.tr(),
              ),
            ),

            const SizedBox(height: 40),
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

// Keep FeedbackFormScreen as an alias for backward compat (not used in nav anymore)
class FeedbackFormScreen extends RateTripScreen {
  const FeedbackFormScreen({
    super.key,
    required super.tripId,
    super.driverId,
    required int rating,
  }) : super(existingReview: null);
}
