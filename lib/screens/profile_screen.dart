import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('profile'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppTheme.accentColor)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 32, bottom: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimalist Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: theme.cardColor,
                          backgroundImage: user?['avatar'] != null 
                            ? NetworkImage(user!['avatar']) 
                            : const NetworkImage('https://ui-avatars.com/api/?name=User&background=FF9900&color=000&size=128'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user?['display_name'] ?? user?['name'] ?? 'passenger_user'.tr(),
                                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (auth.isVerified) const Icon(Icons.verified_rounded, color: AppTheme.accentColor, size: 20),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?['phone'] ?? user?['phone_number'] ?? '+251 900 000 000',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // Supreme Balance Card (Minimalist)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('wulopay_balance'.tr().toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${wallet.balance ?? '0.00'} ETB',
                              style: theme.textTheme.displayLarge?.copyWith(fontSize: 32, color: AppTheme.accentColor),
                            ),
                            Container(
                              decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(16)),
                              child: IconButton(
                                icon: const Icon(Icons.add_rounded, color: Colors.black),
                                onPressed: () => Navigator.pushNamed(context, '/top-up'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildSectionHeader(theme, 'account'.tr()),
                  const SizedBox(height: 16),
                  _ProfileTile(icon: Icons.history_rounded, title: 'trip_history'.tr(), onTap: () => Navigator.pushNamed(context, '/transaction-history')),
                  _ProfileTile(icon: Icons.lock_outline_rounded, title: 'change_password'.tr(), onTap: () => Navigator.pushNamed(context, '/change-password')),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader(theme, 'appearance'.tr()),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ThemeOption(
                        label: 'light'.tr(),
                        isActive: themeProvider.themeMode == ThemeMode.light,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      ),
                      _ThemeOption(
                        label: 'dark'.tr(),
                        isActive: themeProvider.themeMode == ThemeMode.dark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                      _ThemeOption(
                        label: 'system'.tr(),
                        isActive: themeProvider.themeMode == ThemeMode.system,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  _buildSectionHeader(theme, 'preferences'.tr()),
                  const SizedBox(height: 16),
                  _ProfileTile(icon: Icons.language_rounded, title: 'language'.tr(), subtitle: context.locale.languageCode == 'en' ? 'English' : 'አማርኛ', onTap: () => Navigator.pushNamed(context, '/language')),

                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        auth.logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text('log_out'.tr().toUpperCase()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text('${'version'.tr()} 1.0.0', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.hintColor.withOpacity(0.3))),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor.withOpacity(0.5)),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: Icon(icon, color: AppTheme.accentColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)) : null,
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.hintColor.withOpacity(0.3)),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeOption({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.26,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.accentColor : theme.dividerColor.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isActive ? Colors.black : theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
