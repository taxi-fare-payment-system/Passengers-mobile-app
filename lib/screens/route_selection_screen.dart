import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../utils/app_modals.dart';
import 'trip_details_screen.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  int _selectedRouteIndex = -1;
  bool _isSubmitting = false;
  String _scannedStation = 'Scan Station QR';

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // QR Scanner Background
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue?.trim();
                  if (code != null && code != _scannedStation) {
                    setState(() => _scannedStation = code);
                  }
                }
              },
            ),
          ),
          
          // Floating Location Input
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  _buildLocationRow(
                    context,
                    icon: Icons.qr_code_scanner_rounded,
                    color: AppTheme.accentColor,
                    title: 'current_location'.tr(),
                    value: _scannedStation,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Divider(height: 32, color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  _buildLocationRow(
                    context,
                    icon: Icons.location_on_rounded,
                    color: Colors.red,
                    title: 'destination'.tr(),
                    value: _selectedRouteIndex != -1 
                        ? tripProvider.routes[_selectedRouteIndex]['endLocation'] 
                        : 'select_destination'.tr(),
                    isPlaceholder: _selectedRouteIndex == -1,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet for Routes
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 480,
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
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('select_route'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      TextButton(
                        onPressed: () => tripProvider.fetchRoutes(authProvider.token!),
                        child: Text('refresh'.tr().toUpperCase(), style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: tripProvider.isLoading 
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                        : tripProvider.routes.isEmpty
                            ? Center(child: Text('no_routes_available'.tr(), style: theme.textTheme.bodyMedium))
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: tripProvider.routes.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final route = tripProvider.routes[index];
                                  return _RouteCard(
                                    title: route['name'] ?? '${'route'.tr()} ${index + 1}',
                                    subtitle: '${route['startLocation']} → ${route['endLocation']}',
                                    fare: '${route['baseFare']} ${'currency'.tr()}',
                                    time: '${route['estimatedDuration']} ${'mins'.tr()}',
                                    isSelected: _selectedRouteIndex == index,
                                    onTap: () => setState(() => _selectedRouteIndex = index),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_selectedRouteIndex == -1 || _isSubmitting)
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            try {
                              final route = tripProvider.routes[_selectedRouteIndex];
                              final token = authProvider.token!;
                              await tripProvider.fetchVehiclesForRoute(route['id'].toString(), token);
                              if (mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => TripDetailsScreen(route: route)));
                              }
                            } catch (e) {
                              if (mounted) AppModals.showError(context, e.toString().replaceAll('Exception: ', ''));
                            } finally {
                              if (mounted) setState(() => _isSubmitting = false);
                            }
                          },
                    child: _isSubmitting 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                        : Text('confirm_selection'.tr().toUpperCase()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isPlaceholder = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isPlaceholder ? theme.hintColor.withOpacity(0.5) : theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String fare;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteCard({
    required this.title,
    required this.subtitle,
    required this.fare,
    required this.time,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(time, style: TextStyle(color: isSelected ? Colors.black : AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: isSelected ? Colors.black.withOpacity(0.6) : theme.hintColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(
              fare,
              style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.black : AppTheme.accentColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
