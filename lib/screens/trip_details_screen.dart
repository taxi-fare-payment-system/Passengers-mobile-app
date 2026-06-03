import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../utils/app_modals.dart';

class TripDetailsScreen extends StatefulWidget {
  final dynamic route;
  const TripDetailsScreen({super.key, required this.route});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late TripProvider _tripProvider;
  int _selectedVehicleIndex = -1;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _tripProvider = Provider.of<TripProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _tripProvider.stopTripPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final authProvider = context.watch<AuthProvider>();
    final trip = tripProvider.currentTrip;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          trip != null ? '${'trip_status'.tr().toUpperCase()}: ${trip['status']}' : 'confirm_booking'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppTheme.accentColor),
        ),
      ),
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? Colors.grey[900] : const Color(0xFFF3F4F6),
            child: Center(
              child: Icon(Icons.map_rounded, size: 80, color: isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          
          // Content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: trip == null ? 480 : 540,
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, -10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (trip == null) ...[
                    Text('select_available_vehicle'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: tripProvider.vehicles.isEmpty
                          ? Center(child: Text('no_vehicles_available'.tr(), style: theme.textTheme.bodyMedium))
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: tripProvider.vehicles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = tripProvider.vehicles[index];
                                final isSelected = _selectedVehicleIndex == index;
                                return InkWell(
                                  onTap: () => setState(() => _selectedVehicleIndex = index),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.accentColor : theme.cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.accentColor : theme.dividerColor.withOpacity(0.05),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_taxi_rounded, color: isSelected ? Colors.black : AppTheme.accentColor, size: 28),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v['plateNumber'] ?? 'unknown_plate'.tr(), 
                                                style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color)
                                              ),
                                              Text(
                                                '${'driver'.tr()}: ${v['driverName'] ?? 'assigned_soon'.tr()}', 
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.black.withOpacity(0.6) : theme.hintColor)
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.black),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_selectedVehicleIndex == -1 || _isBooking)
                          ? null
                          : () async {
                              setState(() => _isBooking = true);
                              try {
                                final vehicle = tripProvider.vehicles[_selectedVehicleIndex];
                                await tripProvider.createTrip({
                                  'route_id': widget.route['id'],
                                  'vehicle_id': vehicle['id'],
                                  'passenger_id': authProvider.user?['id'],
                                  'start_location': widget.route['startLocation'],
                                  'end_location': widget.route['endLocation'],
                                  'estimated_fare': widget.route['baseFare'],
                                }, authProvider.token!);
                              } catch (e) {
                                if (mounted) AppModals.showException(context, e);
                              } finally {
                                if (mounted) setState(() => _isBooking = false);
                              }
                            },
                      child: _isBooking 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)) 
                        : Text('book_now'.tr().toUpperCase()),
                    ),
                  ] else ...[
                    // Trip Status View
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (trip['status'] ?? 'PENDING').toString().toUpperCase(),
                            style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                          ),
                        ),
                        Text(
                          'estimated_arrival'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        final driverId = trip['driver_id'] ?? trip['driverId'];
                        if (driverId != null) {
                          Navigator.pushNamed(context, '/driver-profile', arguments: {'driverId': driverId.toString()});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                              child: const Icon(Icons.person_rounded, size: 30, color: AppTheme.accentColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trip['driver_name'] ?? 'finding_driver'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                  Text(
                                    tripProvider.vehicleDetails != null 
                                      ? '${tripProvider.vehicleDetails!['metadata']?['model'] ?? 'Vehicle'} • ${tripProvider.vehicleDetails!['plateNumber']}' 
                                      : 'loading_vehicle_details'.tr(),
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.call_rounded, color: Colors.green, size: 28),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTimelineItem(
                      context,
                      icon: Icons.my_location_rounded,
                      color: AppTheme.accentColor,
                      location: trip['start_location'] ?? widget.route['startLocation'],
                      time: 'pickup'.tr(),
                      isFirst: true,
                    ),
                    _buildTimelineItem(
                      context,
                      icon: Icons.location_on_rounded,
                      color: Colors.red,
                      location: trip['end_location'] ?? widget.route['endLocation'],
                      time: 'dropoff'.tr(),
                      isLast: true,
                    ),
                    const Spacer(),
                    if (trip['status'] == 'WAITING_FOR_PASSENGER')
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                        child: Text('show_qr_to_driver'.tr().toUpperCase()),
                      )
                    else if (trip['status'] == 'COMPLETED' || trip['status'] == 'ENDED')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            '/confirm-payment',
                            arguments: {
                              'trip_id': trip['id'],
                              'amount': double.tryParse(trip['estimated_fare']?.toString() ?? '0') ?? 0.0,
                            },
                          );
                        },
                        child: Text('pay_fare'.tr().toUpperCase()),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String location,
    required String time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst) Container(width: 2, height: 10, color: theme.dividerColor.withOpacity(0.1)),
              Icon(icon, color: color, size: 22),
              if (!isLast) Expanded(child: Container(width: 2, color: theme.dividerColor.withOpacity(0.1))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(location, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(time.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
