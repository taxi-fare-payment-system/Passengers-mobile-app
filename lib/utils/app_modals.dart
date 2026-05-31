import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppModals {
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    // Check if the current theme is dark to adjust text colors
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message, 
                style: const TextStyle(
                  color: Colors.black, 
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
