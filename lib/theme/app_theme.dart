import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Construction Industry Design System
/// Professional, reliable, data-dense theme optimized for admin portals
class AppTheme {
  // ========== Color Palette - Construction/Engineering Sector ==========
  
  // Primary Colors - Professional Blue (Trust, Reliability)
  static const Color primaryBlue = Color(0xFF1E40AF); // Deep professional blue
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Lighter blue for accents
  static const Color primaryBlueDark = Color(0xFF1E3A8A); // Darker for headers
  
  // Secondary Colors - Steel Gray (Professional, Industrial)
  static const Color steelGray = Color(0xFF475569); // Main gray
  static const Color steelGrayLight = Color(0xFF64748B); // Light gray
  static const Color steelGrayDark = Color(0xFF334155); // Dark gray
  
  // High-Visibility Accent Colors (Safety-inspired)
  static const Color safetyOrange = Color(0xFFFF6B35); // High visibility orange
  static const Color safetyYellow = Color(0xFFFFC107); // Warning yellow
  static const Color safetyGreen = Color(0xFF10B981); // Success/Go green
  static const Color safetyRed = Color(0xFFEF4444); // Alert red
  
  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC); // Light background
  static const Color surface = Color(0xFFFFFFFF); // Card/container background
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Elevated surface
  
  // Border & Divider
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Almost black
  static const Color textSecondary = Color(0xFF475569); // Medium gray
  static const Color textTertiary = Color(0xFF94A3B8); // Light gray
  static const Color textInverse = Color(0xFFFFFFFF); // White text
  
  // Status Colors
  static const Color statusSuccess = safetyGreen;
  static const Color statusWarning = safetyYellow;
  static const Color statusError = safetyRed;
  static const Color statusInfo = primaryBlueLight;
  
  // Status Backgrounds (Light variants)
  static const Color statusSuccessBg = Color(0xFFD1FAE5);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusErrorBg = Color(0xFFFEE2E2);
  static const Color statusInfoBg = Color(0xFFDBEAFE);
  
  // Chart Colors
  static const List<Color> chartColors = [
    primaryBlue,
    safetyOrange,
    safetyGreen,
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
  ];
  
  // ========== Typography ==========
  static TextTheme getTextTheme() {
    return GoogleFonts.interTextTheme().copyWith(
      // Display - Large headings
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      // Headlines
      headlineLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Body
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        height: 1.4,
      ),
      // Labels
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
      ),
    );
  }
  
  // ========== Spacing System ==========
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // ========== Border Radius ==========
  static const double radiusSM = 6.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  
  // ========== Shadows ==========
  static List<BoxShadow> get shadowSM => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMD => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLG => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  // ========== Theme Data ==========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: steelGray,
        surface: surface,
        background: background,
        error: safetyRed,
        onPrimary: textInverse,
        onSecondary: textInverse,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textInverse,
      ),
      scaffoldBackgroundColor: background,
      textTheme: getTextTheme(),
      fontFamily: GoogleFonts.inter().fontFamily,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: textInverse,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: safetyRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: safetyRed, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textTertiary,
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        deleteIconColor: textSecondary,
        disabledColor: surfaceElevated,
        selectedColor: primaryBlue,
        secondarySelectedColor: statusInfoBg,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSM,
          vertical: spacingXS,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
    );
  }
}

