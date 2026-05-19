import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: Navigator.canPop(context) 
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ) 
        : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!Navigator.canPop(context)) const SizedBox(height: 60),
              // Brand Mark
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.local_taxi_rounded,
                  size: 32,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'WuloPay',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 48),
              ),
              Text(
                'cashless_taxi_fare'.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
              ),
              const Spacer(),
              
              Text(
                'choose_language'.tr(),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'select_preferred_language'.tr(),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              _LanguageOption(
                title: 'አማርኛ (Amharic)',
                onTap: () async {
                  await context.setLocale(const Locale('am'));
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                isActive: context.locale.languageCode == 'am',
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                title: 'English',
                onTap: () async {
                  await context.setLocale(const Locale('en'));
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                isActive: context.locale.languageCode == 'en',
              ),
              
              const Spacer(),
              
              // Appearance Toggle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ThemeToggle(
                      label: 'light'.tr(),
                      isActive: context.watch<ThemeProvider>().themeMode == ThemeMode.light,
                      onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.light),
                    ),
                    _ThemeToggle(
                      label: 'dark'.tr(),
                      isActive: context.watch<ThemeProvider>().themeMode == ThemeMode.dark,
                      onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.dark),
                    ),
                    _ThemeToggle(
                      label: 'system'.tr(),
                      isActive: context.watch<ThemeProvider>().themeMode == ThemeMode.system,
                      onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              if (!Navigator.canPop(context))
                ElevatedButton(
                  onPressed: () async {
                    const storage = FlutterSecureStorage();
                    await storage.write(key: 'has_seen_onboarding', value: 'true');
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text('continue'.tr().toUpperCase()),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const _LanguageOption({required this.title, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accentColor : Theme.of(context).dividerColor.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.black : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isActive) const Icon(Icons.check_circle_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeToggle({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primaryColor) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: isActive 
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                  : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
