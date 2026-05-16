import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/driver_provider.dart';

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
    final isDark = theme.brightness == Brightness.dark;

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
            // Immersive Driver Info
            GestureDetector(
              onTap: () {
                if (widget.driverId != null) {
                  Navigator.pushNamed(context, '/driver-profile', arguments: {'driverId': widget.driverId});
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.driverId ?? 'driver'}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dawit K.', // Fallback name, ideally from trip details
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'how_was_ride'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'feedback_help_improve'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            
            // Modern Stars
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
            
            ElevatedButton(
              onPressed: _rating > 0 
                ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackFormScreen(tripId: widget.tripId, driverId: widget.driverId, rating: _rating))) 
                : null,
              child: Text('continue'.tr().toUpperCase()),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: Text('skip'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
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
  final List<String> _selectedTags = [];
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
            Text('tell_us_more'.tr(), style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 32),
            Text('optional_comments'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'safe_driving'.tr(), 'clean_taxi'.tr(), 'polite_driver'.tr(), 'great_music'.tr(),
                'helpful'.tr(), 'punctual'.tr(), 'good_route'.tr(), 'fair_price'.tr()
              ].map((tag) => _TagChip(
                label: tag,
                isSelected: _selectedTags.contains(tag),
                onSelected: (selected) {
                  setState(() {
                    if (selected) _selectedTags.add(tag);
                    else _selectedTags.remove(tag);
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 40),
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
            ElevatedButton(
              onPressed: feedbackProvider.isSubmitting
                  ? null
                  : () async {
                      try {
                        if (widget.driverId != null) {
                          await driverProvider.submitDriverReview(
                            driverId: widget.driverId!,
                            rating: widget.rating.toDouble(),
                            message: _commentController.text.isNotEmpty ? _commentController.text : 'No comment provided',
                            token: auth.token!,
                            headers: auth.headers,
                          );
                        } else {
                          await feedbackProvider.submitFeedback(
                            tripId: widget.tripId,
                            rating: widget.rating,
                            tags: _selectedTags,
                            comment: _commentController.text,
                            token: auth.token!,
                            headers: auth.headers,
                          );
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('feedback_submitted_thanks'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
              child: feedbackProvider.isSubmitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                  : Text('submit_feedback'.tr().toUpperCase()),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _TagChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppTheme.accentColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? AppTheme.accentColor : Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    );
  }
}
