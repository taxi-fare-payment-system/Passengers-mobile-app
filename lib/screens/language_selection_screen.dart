import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.local_taxi_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'WuloPay',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'cashless_taxi_fare'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                'choose_language'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'select_preferred_language'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _LanguageButton(
                title: 'አማርኛ (Amharic)',
                onTap: () {
                  context.setLocale(const Locale('am'));
                },
                isActive: context.locale.languageCode == 'am',
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                title: 'English',
                onTap: () {
                  context.setLocale(const Locale('en'));
                },
                isActive: context.locale.languageCode == 'en',
              ),
              const Spacer(),
              
              // Theme Toggle Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_rounded, color: Theme.of(context).primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text('Appearance', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ThemeOption(
                          icon: Icons.light_mode_rounded,
                          label: 'Light',
                          isActive: context.watch<ThemeProvider>().themeMode == ThemeMode.light,
                          onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.light),
                        ),
                        _ThemeOption(
                          icon: Icons.dark_mode_rounded,
                          label: 'Dark',
                          isActive: context.watch<ThemeProvider>().themeMode == ThemeMode.dark,
                          onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.dark),
                        ),
                        _ThemeOption(
                          icon: Icons.brightness_auto_rounded,
                          label: 'System',
                          isActive: context.watch<ThemeProvider>().themeMode == ThemeMode.system,
                          onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              if (!Navigator.canPop(context))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('continue'.tr()),
                  ),
                ),
              const Spacer(),
              Text(
                'secure_seamless_payments'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const _LanguageButton({
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Theme.of(context).dividerColor,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
            Icon(
              isActive ? Icons.check_circle : Icons.language,
              color: isActive ? Colors.white : Theme.of(context).hintColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.primaryColor : theme.dividerColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
