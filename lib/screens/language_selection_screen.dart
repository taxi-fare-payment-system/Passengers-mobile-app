import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
                'Cashless Taxi fare',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                'Choose Language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferred language to continue',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _LanguageButton(
                title: 'አማርኛ (Amharic)',
                onTap: () => Navigator.pushNamed(context, '/login'),
                isActive: true,
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                title: 'English',
                onTap: () => Navigator.pushNamed(context, '/login'),
                isActive: false,
              ),
              const Spacer(flex: 2),
              Text(
                'SECURE & SEAMLESS PAYMENTS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary.withOpacity(0.4),
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
          color: isActive ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
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
                    color: isActive ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
            Icon(
              isActive ? Icons.check_circle : Icons.language,
              color: isActive ? Colors.white : AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
