import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KAYAN LNG Brand Colors
class KayanColors {
  // Primary Navy Blue
  static const Color navy = Color(0xFF2B4C7E);
  static const Color navyDark = Color(0xFF1E3A5F);
  static const Color navyLight = Color(0xFF3D5F8F);
  
  // Orange Accent
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFF8555);
  static const Color orangeDark = Color(0xFFE55A2B);
  
  // Sky Blue
  static const Color skyBlue = Color(0xFF60A5FA);
  
  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
}

/// KAYAN LNG Theme Configuration
class KayanTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: KayanColors.navy, // Industrial Blue
        primaryContainer: KayanColors.navyLight,
        secondary: KayanColors.orange, // Minimal Orange Accent
        secondaryContainer: KayanColors.orangeLight,
        surface: KayanColors.white,
        surfaceContainerHighest: KayanColors.gray50, // Lighter background for inputs/containers
        error: KayanColors.error,
        onPrimary: KayanColors.white,
        onSecondary: KayanColors.white,
        onSurface: KayanColors.gray900,
        onError: KayanColors.white,
        outline: KayanColors.gray300,
        outlineVariant: KayanColors.gray200,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: KayanColors.gray50, // White dominant background (very light gray)
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: KayanColors.white,
        foregroundColor: KayanColors.navy, // Dark text/icons on white app bar
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: KayanColors.gray900.withOpacity(0.1),
        shape: const Border(bottom: BorderSide(color: KayanColors.gray200, width: 1)),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: KayanColors.navy,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: KayanColors.navy,
          size: 24,
        ),
      ),
      
      // Card Theme (Soft shadow, rounded corners)
      // cardTheme: CardTheme(
      //   color: KayanColors.white,
      //   elevation: 2,
      //   shadowColor: KayanColors.gray900.withOpacity(0.08),
      //   surfaceTintColor: Colors.transparent, // Remove M3 tint
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(12), // 10-12px as requested
      //     side: const BorderSide(color: KayanColors.gray200, width: 1), // Subtle border
      //   ),
      //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //   clipBehavior: Clip.antiAlias,
      // ),
      
      // Elevated Button (Flat, no gradient)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KayanColors.navy,
          foregroundColor: KayanColors.white,
          elevation: 0, // Flat
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
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KayanColors.navy,
          side: const BorderSide(color: KayanColors.gray300, width: 1),
          backgroundColor: KayanColors.white,
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
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KayanColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration (Clean, Industrial)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KayanColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KayanColors.gray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KayanColors.gray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KayanColors.navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KayanColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KayanColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: KayanColors.gray600,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: KayanColors.gray400,
        ),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: KayanColors.gray900),
        subtitleTextStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.normal, color: KayanColors.gray600),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: KayanColors.gray200,
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: KayanColors.white,
        selectedItemColor: KayanColors.navy,
        unselectedItemColor: KayanColors.gray400,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      // Tab Bar
      // tabBarTheme: TabBarTheme(
      //   labelColor: KayanColors.navy,
      //   unselectedLabelColor: KayanColors.gray500,
      //   indicatorColor: KayanColors.navy,
      //   dividerColor: KayanColors.gray200,
      //   labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      //   unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      // ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KayanColors.white;
          }
          return KayanColors.gray500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KayanColors.navy;
          }
          return KayanColors.gray200;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KayanColors.navy;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(KayanColors.white),
        side: const BorderSide(color: KayanColors.gray400, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KayanColors.navy;
          }
          return KayanColors.gray400;
        }),
      ),
    );
  }
}
