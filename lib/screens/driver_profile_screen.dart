import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text('driver_profile'.tr())),
        body: Center(child: Text('driver_not_found'.tr())),
      );
    }

    final reviews = driver['reviews'] ?? {};
    final reviewList = reviews['reviews'] as List? ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('driver_profile'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Driver Identity
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: NetworkImage(driver['avatar'] ?? 'https://i.pravatar.cc/150?u=${driver['id']}'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver['display_name'] ?? 'Unknown Driver', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                            Row(
                              children: [
                                if (driver['is_verified'] == true) ...[
                                  const Icon(Icons.verified, color: AppTheme.accentColor, size: 18),
                                  const SizedBox(width: 4),
                                  Text('verified'.tr(), style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'rating'.tr(), value: '${reviews['averageRating'] ?? '0.0'}', icon: Icons.star_rounded, color: Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'reviews'.tr(), value: '${reviews['count'] ?? 0}', icon: Icons.rate_review_rounded, color: AppTheme.accentColor)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call_rounded, size: 20),
                          label: Text('call_driver'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 64),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Reviews Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('recent_reviews'.tr().toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  ),
                  const SizedBox(height: 16),
                  if (reviewList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(child: Text('no_reviews_yet'.tr())),
                    )
                  else
                    ...reviewList.map((review) => _ReviewCard(review: review)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.read<DriverProvider>();
    final date = DateTime.tryParse(review['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: driverProvider.getPublicProfile(review['reviewer_id']?.toString() ?? ''),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data?['name'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  );
                },
              ),
              Text(DateFormat('MMM dd').format(date), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star_rounded,
              size: 14,
              color: index < (review['rating'] ?? 0) ? Colors.orange : Colors.grey[300],
            )),
          ),
          const SizedBox(height: 12),
          Text(review['message'] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
