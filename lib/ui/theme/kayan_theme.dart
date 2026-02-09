import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KAYAN LNG Brand Colors (Dark Theme Palette)
class KayanColors {
  // Primary - Neon Blue
  static const Color navy = Color(0xFF3B82F6); // --neon-blue
  static const Color navyDark = Color(0xFF2563EB); // --primary-hover
  static const Color navyLight = Color(0xFF60A5FA); // Blue 400
  
  // Accents
  static const Color orange = Color(0xFFF59E0B); // --neon-orange
  static const Color success = Color(0xFF10B981); // --neon-green
  static const Color warning = Color(0xFFF59E0B); // --neon-orange
  static const Color error = Color(0xFFEF4444); // --neon-red
  
  // Dark Backgrounds
  static const Color background = Color(0xFF12141A); // --dark-bg
  static const Color surface = Color(0xFF1C1F26); // --dark-card
  static const Color surfaceHighlight = Color(0xFF2D323E); // --dark-border

  // Text Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFE2E4E9); // --dark-text-main
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF9499A6); // --dark-text-muted
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Light versions for badges
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color orangeDark = Color(0xFFB45309);
  
  static const Color inputBackground = Color(0xFF0F1115); 
}

/// KAYAN LNG Theme Configuration
class KayanTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: KayanColors.navy,
        primaryContainer: KayanColors.navyDark,
        secondary: KayanColors.orange,
        surface: KayanColors.surface,
        error: KayanColors.error,
        onPrimary: KayanColors.white,
        onSecondary: KayanColors.white,
        onSurface: KayanColors.gray100,
        onError: KayanColors.white,
        outline: KayanColors.gray500,
        outlineVariant: KayanColors.surfaceHighlight,
      ),
      
      scaffoldBackgroundColor: KayanColors.background,
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: KayanColors.white),
        displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: KayanColors.white),
        displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: KayanColors.white),
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: KayanColors.white),
        headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: KayanColors.white),
        headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: KayanColors.white),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: KayanColors.white),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: KayanColors.gray100),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: KayanColors.gray100),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: KayanColors.gray100),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: KayanColors.gray100),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: KayanColors.gray400),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: KayanColors.white),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: KayanColors.gray400),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: KayanColors.gray500),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: KayanColors.surface,
        foregroundColor: KayanColors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: KayanColors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: KayanColors.white,
          size: 24,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: KayanColors.surface,
        elevation: 4,
        surfaceTintColor: Colors.transparent, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: KayanColors.surfaceHighlight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KayanColors.navy,
          foregroundColor: KayanColors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KayanColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KayanColors.surfaceHighlight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KayanColors.surfaceHighlight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KayanColors.navyLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KayanColors.error, width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: KayanColors.gray400,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: KayanColors.gray500,
        ),
      ),
    );
  }
}
