import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE5E7EB),
            child: Center(
              child: Icon(Icons.map_outlined, size: 100, color: Colors.black12),
            ),
          ),
          
          // Floating Location Input
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLocationRow(
                    icon: Icons.my_location_rounded,
                    color: AppTheme.primaryColor,
                    title: 'Current Location',
                    value: 'Megenagna Station',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Divider(height: 24),
                  ),
                  _buildLocationRow(
                    icon: Icons.location_on_rounded,
                    color: Colors.red,
                    title: 'Destination',
                    value: 'Select Destination',
                    isPlaceholder: true,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet for Routes
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 400,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Select Route',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        _RouteCard(
                          title: 'Bole 1',
                          subtitle: 'Megenagna -> Stadium',
                          fare: '15.00 ETB',
                          time: '12 mins away',
                          isSelected: true,
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _RouteCard(
                          title: 'Bole 5',
                          subtitle: 'Megenagna -> Bole',
                          fare: '25.00 ETB',
                          time: '5 mins away',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _RouteCard(
                          title: 'German Terminal',
                          subtitle: 'Megenagna -> CMC',
                          fare: '20.00 ETB',
                          time: '8 mins away',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/confirm-payment'),
                    child: const Text('Confirm Selection'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isPlaceholder = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isPlaceholder ? AppTheme.textSecondary : AppTheme.textPrimary,
              ),
            ),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
            width: isSelected ? 2 : 1,
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(time, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              fare,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
