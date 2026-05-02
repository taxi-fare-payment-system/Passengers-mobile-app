import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Destination', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildLocationInput(
                  icon: Icons.my_location_rounded,
                  iconColor: AppTheme.primaryColor,
                  label: 'Current Location',
                  value: 'Megenagna Station',
                  isReadOnly: true,
                ),
                const SizedBox(height: 12),
                _buildLocationInput(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.red,
                  label: 'Destination',
                  hint: 'Where are you going?',
                  controller: _destinationController,
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Available Connect Routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _RouteCard(
                  title: 'Bole 1',
                  subtitle: 'Megenagna -> Stadium',
                  fare: '15.00 ETB',
                  time: '12 mins away',
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/confirm-payment'),
              child: const Text('Confirm Selection'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    String? hint,
    bool isReadOnly = false,
    TextEditingController? controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                if (isReadOnly)
                  Text(value!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))
                else
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String fare;
  final String time;
  final VoidCallback onTap;

  const _RouteCard({
    required this.title,
    required this.subtitle,
    required this.fare,
    required this.time,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
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
