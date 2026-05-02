import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RateTripScreen extends StatefulWidget {
  const RateTripScreen({super.key});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driver1')),
            const SizedBox(height: 16),
            const Text('Rate your trip', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('How was your ride with Dawit?', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainManager.center,
              children: List.generate(5, (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              )),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackFormScreen())),
              child: const Text('Submit Rating'),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
          ],
        ),
      ),
    );
  }
}

class FeedbackFormScreen extends StatelessWidget {
  const FeedbackFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Feedback', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anything else you want to share?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your experience here...',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Optional Comments', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ['Safe Driving', 'Clean Taxi', 'Polite Driver', 'Great Music'].map((tag) => FilterChip(
                label: Text(tag),
                onSelected: (val) {},
                backgroundColor: AppTheme.surfaceColor,
              )).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
