import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driver1'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dawit K.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainManager.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('(120 reviews)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainManager.spaceEvenly,
              children: [
                _DriverStat(label: 'Trips', value: '1.2k'),
                _DriverStat(label: 'Exp', value: '3 yrs'),
                _DriverStat(label: 'Rating', value: '4.8'),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About Dawit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text(
                    'Dawit is a professional driver with over 3 years of experience in Addis Ababa. Known for punctuality and safe driving.',
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 16),
            _ReviewItem(
              name: 'Samuel A.',
              rating: 5,
              comment: 'Great driver, very polite and reached destination on time.',
              date: 'Jan 20, 2024',
            ),
            const SizedBox(height: 12),
            _ReviewItem(
              name: 'Hana G.',
              rating: 4,
              comment: 'Safe driving. Clean taxi.',
              date: 'Jan 15, 2024',
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverStat extends StatelessWidget {
  final String label;
  final String value;

  const _DriverStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;
  final String date;

  const _ReviewItem({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainManager.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star_rounded,
                size: 14,
                color: index < rating ? Colors.orange : Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
