import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            // Profile Header
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=samuel'),
            ),
            const SizedBox(height: 16),
            Text(
              'Samuel Abera',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '+251 91 234 5678',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            
            // Settings Groups
            _buildSection(
              context,
              'Account',
              [
                _ProfileTile(icon: Icons.person_outline_rounded, title: 'Edit Profile', onTap: () {}),
                _ProfileTile(icon: Icons.payment_rounded, title: 'Payment Methods', onTap: () {}),
                _ProfileTile(icon: Icons.security_rounded, title: 'Security (PIN/Biometric)', onTap: () {}),
              ],
            ),
            _buildSection(
              context,
              'Preferences',
              [
                _ProfileTile(icon: Icons.language_rounded, title: 'Language', subtitle: 'English', onTap: () {}),
                _ProfileTile(icon: Icons.notifications_none_rounded, title: 'Notification Settings', onTap: () {}),
              ],
            ),
            _buildSection(
              context,
              'Support',
              [
                _ProfileTile(icon: Icons.help_outline_rounded, title: 'Help Center', onTap: () {}),
                _ProfileTile(icon: Icons.policy_outlined, title: 'Privacy Policy', onTap: () {}),
                _ProfileTile(icon: Icons.info_outline_rounded, title: 'About WuloPay', onTap: () {}),
              ],
            ),
            
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            const Text('Version 1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
        const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
