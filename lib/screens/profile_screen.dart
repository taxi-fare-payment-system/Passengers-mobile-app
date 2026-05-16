import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile'.tr(), style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: const CircleAvatar(
                          radius: 46,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=passenger'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?['display_name'] ?? user?['name'] ?? 'passenger_user'.tr(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                      ),
                      if (auth.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: AppTheme.primaryColor, size: 18),
                      ],
                    ],
                  ),
                  Text(
                    user?['phone'] ?? user?['phone_number'] ?? '+251 900 000 000',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Wallet Balance Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('wulopay_balance'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${wallet.balance ?? '0.00'} ETB', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/top-up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      foregroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('top_up'.tr()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings Menu
            _buildSection(
              context,
              'account'.tr(),
              [
                _ProfileTile(icon: Icons.history_rounded, title: 'trip_history'.tr(), onTap: () => Navigator.pushNamed(context, '/transaction-history')),
                _ProfileTile(icon: Icons.lock_outline_rounded, title: 'change_password'.tr(), onTap: () => Navigator.pushNamed(context, '/change-password')),
              ],
            ),
            _buildSection(
              context,
              'preferences'.tr(),
              [
                _ProfileTile(icon: Icons.language_rounded, title: 'language'.tr(), subtitle: 'English', onTap: () => Navigator.pushNamed(context, '/language')),
              ],
            ),
            _buildSection(
              context,
              'support'.tr(),
              [
                _ProfileTile(icon: Icons.help_outline_rounded, title: 'help_center'.tr(), onTap: () {}),
                _ProfileTile(icon: Icons.info_outline_rounded, title: 'about_wulopay'.tr(), onTap: () {}),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: Text('log_out'.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                ),
              ),
            ),
            Text('${'version'.tr()} 1.0.0', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 40),
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
          padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
