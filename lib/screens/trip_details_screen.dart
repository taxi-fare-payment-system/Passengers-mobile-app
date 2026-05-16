import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
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
    // Stop polling when leaving the screen
    _tripProvider.stopTripPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final authProvider = context.watch<AuthProvider>();
    final trip = tripProvider.currentTrip;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          trip != null ? '${'trip_status'.tr()}: ${trip['status']}' : 'confirm_booking'.tr(),
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE5E7EB),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 100, color: Colors.black12),
            ),
          ),
          
          // Content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: trip == null ? 450 : 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (trip == null) ...[
                    Text('select_available_vehicle'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: tripProvider.vehicles.isEmpty
                          ? Center(child: Text('no_vehicles_available'.tr()))
                          : ListView.separated(
                              itemCount: tripProvider.vehicles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = tripProvider.vehicles[index];
                                return InkWell(
                                  onTap: () => setState(() => _selectedVehicleIndex = index),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _selectedVehicleIndex == index ? AppTheme.primaryColor : Colors.grey[200]!,
                                        width: _selectedVehicleIndex == index ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      color: _selectedVehicleIndex == index ? AppTheme.primaryColor.withOpacity(0.05) : Theme.of(context).cardColor,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.directions_car_filled, color: AppTheme.primaryColor),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(v['plateNumber'] ?? 'unknown_plate'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text('${'driver'.tr()}: ${v['driverName'] ?? 'assigned_soon'.tr()}', style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                } finally {
                                  if (mounted) setState(() => _isBooking = false);
                                }
                              },
                        child: _isBooking ? const CircularProgressIndicator(color: Colors.white) : Text('book_now'.tr()),
                      ),
                    ),
                  ] else ...[
                    // Trip Status View
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            trip['status'] ?? 'PENDING',
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Text(
                          'estimated_arrival'.tr(),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.surfaceColor,
                          child: Icon(Icons.person, size: 30, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trip['driver_name'] ?? 'finding_driver'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(
                                tripProvider.vehicleDetails != null 
                                  ? '${tripProvider.vehicleDetails!['metadata']?['model'] ?? 'Vehicle'} • ${tripProvider.vehicleDetails!['plateNumber']}' 
                                  : 'Loading vehicle details...',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.call, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildTimelineItem(
                      icon: Icons.my_location_rounded,
                      color: AppTheme.primaryColor,
                      location: trip['start_location'] ?? widget.route['startLocation'],
                      time: 'pickup'.tr(),
                      isFirst: true,
                    ),
                    _buildTimelineItem(
                      icon: Icons.location_on_rounded,
                      color: Colors.red,
                      location: trip['end_location'] ?? widget.route['endLocation'],
                      time: 'dropoff'.tr(),
                      isLast: true,
                    ),
                    const Spacer(),
                    if (trip['status'] == 'WAITING_FOR_PASSENGER')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: Text('show_qr_to_driver'.tr()),
                        ),
                      )
                    else if (trip['status'] == 'COMPLETED' || trip['status'] == 'ENDED')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                          child: Text('pay_fare'.tr()),
                        ),
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

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String location,
    required String time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst) Container(width: 2, height: 10, color: Colors.grey[200]),
              Icon(icon, color: color, size: 20),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[200])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(location, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
