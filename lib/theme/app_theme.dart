import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Walldot Builders Design System
/// Professional construction company theme with brand identity colors
class AppTheme {
  // ========== Walldot Builders Color Palette ==========
  
  // Primary Brand Colors
  static const Color deepSlate = Color(0xFF2A2A3A); // Primary brand color - headers, nav
  static const Color deepSlateDark = Color(0xFF1F1F2E); // Darker variant
  static const Color deepSlateLight = Color(0xFF3A3A4A); // Lighter variant
  
  // Accent Colors - Walldot Signature
  static const Color coralRed = Color(0xFFF36F72); // Primary accent - CTAs, highlights
  static const Color coralRedDark = Color(0xFFE15F62); // Hover/pressed state
  static const Color coralRedLight = Color(0xFFF58B8D); // Light variant
  
  // Secondary Accent
  static const Color constructionOrange = Color(0xFFFF8C42); // Secondary actions, warnings
  static const Color constructionOrangeDark = Color(0xFFE67D38); // Darker variant
  
  // Supporting Colors
  static const Color skyBlue = Color(0xFF56CCF2); // Info, links
  static const Color successGreen = Color(0xFF4CAF50); // Success states
  static const Color warningAmber = Color(0xFFFFC107); // Warnings
  static const Color errorRed = Color(0xFFDC3545); // Errors
  
  // Neutral Colors
  static const Color background = Color(0xFFF7F7F7); // Main background
  static const Color surface = Color(0xFFFFFFFF); // Cards/containers
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Elevated surfaces
  
  // Border & Divider
  static const Color borderLight = Color(0xFFCED4DA);
  static const Color borderMedium = Color(0xFFADB5BD);
  static const Color divider = Color(0xFFE2E8F0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF333333); // Primary text
  static const Color textSecondary = Color(0xFF6C757D); // Secondary text
  static const Color textTertiary = Color(0xFF94A3B8); // Tertiary text
  static const Color textInverse = Color(0xFFFFFFFF); // White text on dark
  
  // Backward compatibility aliases (maintains existing code)
  static const Color primaryBlue = deepSlate;
  static const Color primaryBlueLight = deepSlateLight;
  static const Color primaryBlueDark = deepSlateDark;
  static const Color steelGray = textSecondary;
  static const Color steelGrayLight = Color(0xFF94A3B8);
  static const Color steelGrayDark = deepSlate;
  static const Color safetyOrange = constructionOrange;
  static const Color safetyYellow = warningAmber;
  static const Color safetyGreen = successGreen;
  static const Color safetyRed = errorRed;
  
  // Status Colors
  static const Color statusSuccess = successGreen;
  static const Color statusWarning = warningAmber;
  static const Color statusError = errorRed;
  static const Color statusInfo = skyBlue;
  
  // Status Backgrounds (Light variants)
  static const Color statusSuccessBg = Color(0xFFD1FAE5);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusErrorBg = Color(0xFFFEE2E2);
  static const Color statusInfoBg = Color(0xFFDBEAFE);
  
  // Chart Colors - Walldot Brand Palette
  static const List<Color> chartColors = [
    coralRed,
    constructionOrange,
    successGreen,
    skyBlue,
    deepSlate,
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];
  
  // Additional color aliases for backward compatibility
  static const Color backgroundWhite = surface; // White background
  static const Color walldotGold = Color(0xFFF9A825); // Gold accent color
  
  // ========== Typography ==========
  
  // Static text style getters for convenience
  static TextStyle get bodyLarge => getTextTheme().bodyLarge!;
  static TextStyle get bodyMedium => getTextTheme().bodyMedium!;
  static TextStyle get bodySmall => getTextTheme().bodySmall!;
  static TextStyle get headlineLarge => getTextTheme().headlineLarge!;
  static TextStyle get headlineMedium => getTextTheme().headlineMedium!;
  static TextStyle get headlineSmall => getTextTheme().headlineSmall!;
  static TextStyle get titleLarge => getTextTheme().titleLarge!;
  static TextStyle get titleMedium => getTextTheme().titleMedium!;
  static TextStyle get titleSmall => getTextTheme().titleSmall!;
  static TextStyle get labelLarge => getTextTheme().labelLarge!;
  static TextStyle get labelMedium => getTextTheme().labelMedium!;
  static TextStyle get labelSmall => getTextTheme().labelSmall!;
  static TextTheme getTextTheme() {
    return GoogleFonts.manropeTextTheme().copyWith(
      // Display - Large headings
      displayLarge: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      // Headlines
      headlineLarge: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Body
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        height: 1.4,
      ),
      // Labels
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textTertiary,
        letterSpacing: 0.5,
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
        primary: coralRed, // Walldot accent color for primary actions
        secondary: deepSlate, // Walldot brand color for secondary elements
        surface: surface,
        background: background,
        error: errorRed,
        onPrimary: textInverse,
        onSecondary: textInverse,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textInverse,
      ),
      scaffoldBackgroundColor: background,
      textTheme: getTextTheme(),
      fontFamily: GoogleFonts.manrope().fontFamily,
      
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
          backgroundColor: coralRed, // Walldot signature coral red for CTAs
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
          foregroundColor: deepSlate, // Walldot brand color for outlined buttons
          side: const BorderSide(color: deepSlate, width: 1.5),
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
      
      // Page Transitions Theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
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

