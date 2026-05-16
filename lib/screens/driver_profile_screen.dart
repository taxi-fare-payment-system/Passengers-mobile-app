import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/driver_provider.dart';
import '../providers/auth_provider.dart';

class DriverProfileScreen extends StatefulWidget {
  final String? driverId;
  const DriverProfileScreen({super.key, this.driverId});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.driverId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = context.read<AuthProvider>();
        context.read<DriverProvider>().fetchDriverProfile(widget.driverId!, auth.token!, headers: auth.headers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final driver = driverProvider.currentDriverProfile;
    final isLoading = driverProvider.isLoading;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(title: Text('driver_profile'.tr())),
        body: Center(child: Text('driver_not_found'.tr())),
      );
    }

    final reviews = driver['reviews'] ?? {};
    final reviewList = reviews['reviews'] as List? ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('driver_profile'.tr(), style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(driver['avatar'] ?? 'https://i.pravatar.cc/150?u=${driver['id']}'),
                ),
                if (driver['is_verified'] == true)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.verified, color: Colors.blue, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(driver['display_name'] ?? 'Unknown Driver', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (driver['is_phone_verified'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('phone_verified'.tr(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'rating'.tr(), value: '${reviews['averageRating'] ?? '0.0'}', icon: Icons.star_rounded, iconColor: Colors.orange),
                _StatItem(label: 'reviews_count'.tr(), value: '${reviews['count'] ?? 0}', icon: Icons.rate_review_rounded, iconColor: AppTheme.primaryColor),
                _StatItem(label: 'sub_city'.tr(), value: '${driver['sub_city_id'] ?? '-'}', icon: Icons.location_on_rounded, iconColor: Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: Text('send_message'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.call_rounded, color: AppTheme.primaryColor),
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('recent_reviews'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 16),
            if (reviewList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('no_reviews_yet'.tr(), style: const TextStyle(color: AppTheme.textSecondary)),
              )
            else
              ...reviewList.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ReviewItem(
                  reviewerId: review['reviewer_id'],
                  date: _formatDate(review['created_at']),
                  rating: (review['rating'] as num?)?.toInt() ?? 0,
                  comment: review['message'] ?? '',
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String? reviewerId;
  final String date;
  final int rating;
  final String comment;

  const _ReviewItem({
    required this.reviewerId,
    required this.date,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.read<DriverProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              reviewerId == null 
                ? const Text('Anonymous', style: TextStyle(fontWeight: FontWeight.bold))
                : FutureBuilder<Map<String, dynamic>?>(
                    future: driverProvider.getPublicProfile(reviewerId!),
                    builder: (context, snapshot) {
                      final name = snapshot.data?['name'] ?? 'User';
                      return Text(name, style: const TextStyle(fontWeight: FontWeight.bold));
                    },
                  ),
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star_rounded,
              size: 16,
              color: index < rating ? Colors.orange : Colors.grey[300],
            )),
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
