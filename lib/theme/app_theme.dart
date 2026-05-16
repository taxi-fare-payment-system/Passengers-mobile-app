import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF101828); 
  static const Color accentColor = Color(0xFFFF9900); 
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF3F4F6); // Slightly darker for better contrast in light mode
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFFE5E7EB);

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : backgroundColor;
    final Color cardColor = isDark ? const Color(0xFF111827) : surfaceColor;
    final Color txtPrimary = isDark ? Colors.white : textPrimary;
    final Color txtSecondary = isDark ? const Color(0xFF9CA3AF) : textSecondary;

    return ThemeData(
      brightness: brightness,
      primaryColor: isDark ? Colors.white : primaryColor,
      scaffoldBackgroundColor: bgColor,
      cardColor: cardColor,
      dividerColor: isDark ? const Color(0xFF1F2937) : dividerColor,
      hintColor: txtSecondary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: txtPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Colors.white,
              secondary: accentColor,
              surface: Color(0xFF111827),
              onPrimary: Colors.black,
              onSurface: Colors.white,
            )
          : const ColorScheme.light(
              primary: primaryColor,
              secondary: accentColor,
              surface: surfaceColor,
              onPrimary: Colors.white,
              onSurface: textPrimary,
            ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: txtPrimary,
          letterSpacing: -1.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: txtPrimary,
          letterSpacing: -0.8,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 17,
          color: txtPrimary,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 15,
          color: txtSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: txtSecondary,
          letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? Colors.white : primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: txtSecondary, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: txtSecondary.withOpacity(0.5)),
      ),
    );
  }
}
