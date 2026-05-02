import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

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
        title: const Text('Trip Details', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Map Placeholder (Full background)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE5E7EB),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 100, color: Colors.black12),
            ),
          ),
          
          // Trip Info Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 120), // Space for AppBar
                
                // Trip Summary Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const Text(
                            '24 Jan 2024, 10:35 AM',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '15.00 ETB',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const Divider(height: 40),
                      
                      // Driver Info
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driver1'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dawit K.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                                    const Text(' 5.0 rating', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Toyota Vitz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const Text('2-A34567', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Timeline
                      _buildTimelineItem(
                        icon: Icons.my_location_rounded,
                        color: AppTheme.primaryColor,
                        location: 'Megenagna Station',
                        time: '10:15 AM',
                        isFirst: true,
                      ),
                      _buildTimelineItem(
                        icon: Icons.location_on_rounded,
                        color: Colors.red,
                        location: 'Stadium Station',
                        time: '10:35 AM',
                        isLast: true,
                      ),
                      
                      const Divider(height: 48),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method', style: TextStyle(color: AppTheme.textSecondary)),
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              const Text('WuloPay Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Download Receipt', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/rate-trip'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Rate Trip'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      _buildHelpRow(icon: Icons.help_outline_rounded, title: 'Need help with a trip?', color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      _buildHelpRow(icon: Icons.report_problem_outlined, title: 'Report a problem', color: Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow({required IconData icon, required String title, required Color color}) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.5)),
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
