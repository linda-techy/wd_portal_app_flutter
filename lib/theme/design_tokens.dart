import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Premium Design Tokens System
/// Centralized design system tokens following 8pt grid and Material Design 3 principles
class DesignTokens {
  // ========== Spacing System (8pt Grid) ==========
  /// 4pt - Extra small spacing
  static const double spacingXS = 4.0;
  
  /// 8pt - Small spacing
  static const double spacingSM = 8.0;
  
  /// 12pt - Small-medium spacing
  static const double spacingSM2 = 12.0;
  
  /// 16pt - Medium spacing (base unit)
  static const double spacingMD = 16.0;
  
  /// 20pt - Medium-large spacing
  static const double spacingMD2 = 20.0;
  
  /// 24pt - Large spacing
  static const double spacingLG = 24.0;
  
  /// 32pt - Extra large spacing
  static const double spacingXL = 32.0;
  
  /// 40pt - Extra extra large spacing
  static const double spacingXXL = 40.0;
  
  /// 48pt - 2XL spacing
  static const double spacing2XL = 48.0;
  
  /// 64pt - 3XL spacing
  static const double spacing3XL = 64.0;
  
  /// 80pt - 4XL spacing
  static const double spacing4XL = 80.0;
  
  /// 96pt - 5XL spacing
  static const double spacing5XL = 96.0;

  // ========== Typography Scale ==========
  /// Display Large - 36px / 2.25rem
  static const double fontSizeDisplayLarge = 36.0;
  
  /// Display Medium - 28px / 1.75rem
  static const double fontSizeDisplayMedium = 28.0;
  
  /// Display Small - 24px / 1.5rem
  static const double fontSizeDisplaySmall = 24.0;
  
  /// Headline Large - 22px / 1.375rem
  static const double fontSizeHeadlineLarge = 22.0;
  
  /// Headline Medium - 20px / 1.25rem
  static const double fontSizeHeadlineMedium = 20.0;
  
  /// Headline Small - 18px / 1.125rem
  static const double fontSizeHeadlineSmall = 18.0;
  
  /// Title Large - 16px / 1rem
  static const double fontSizeTitleLarge = 16.0;
  
  /// Title Medium - 14px / 0.875rem
  static const double fontSizeTitleMedium = 14.0;
  
  /// Title Small - 12px / 0.75rem
  static const double fontSizeTitleSmall = 12.0;
  
  /// Body Large - 16px / 1rem
  static const double fontSizeBodyLarge = 16.0;
  
  /// Body Medium - 14px / 0.875rem
  static const double fontSizeBodyMedium = 14.0;
  
  /// Body Small - 12px / 0.75rem
  static const double fontSizeBodySmall = 12.0;
  
  /// Label Large - 14px / 0.875rem
  static const double fontSizeLabelLarge = 14.0;
  
  /// Label Medium - 12px / 0.75rem
  static const double fontSizeLabelMedium = 12.0;
  
  /// Label Small - 11px / 0.6875rem
  static const double fontSizeLabelSmall = 11.0;
  
  /// Caption - 10px / 0.625rem
  static const double fontSizeCaption = 10.0;

  // Line Heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter Spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;

  // ========== Border Radius ==========
  /// 4px - Extra small radius
  static const double radiusXS = 4.0;
  
  /// 6px - Small radius
  static const double radiusSM = 6.0;
  
  /// 8px - Small-medium radius
  static const double radiusSM2 = 8.0;
  
  /// 12px - Medium radius (default)
  static const double radiusMD = 12.0;
  
  /// 16px - Large radius
  static const double radiusLG = 16.0;
  
  /// 20px - Extra large radius
  static const double radiusXL = 20.0;
  
  /// 24px - 2XL radius
  static const double radius2XL = 24.0;
  
  /// 32px - 3XL radius (pill shape)
  static const double radius3XL = 32.0;
  
  /// Fully rounded (circular)
  static const double radiusFull = 9999.0;

  // ========== Elevation System (Material Design 3) ==========
  /// Elevation 0 - No shadow (flat surfaces)
  static const double elevation0 = 0.0;
  
  /// Elevation 1 - Subtle elevation (cards at rest)
  static const double elevation1 = 1.0;
  
  /// Elevation 2 - Low elevation (raised buttons)
  static const double elevation2 = 2.0;
  
  /// Elevation 3 - Medium elevation (cards hover)
  static const double elevation3 = 3.0;
  
  /// Elevation 4 - High elevation (dialogs)
  static const double elevation4 = 4.0;
  
  /// Elevation 5 - Very high elevation (modals)
  static const double elevation5 = 5.0;
  
  /// Elevation 8 - Maximum elevation (tooltips)
  static const double elevation8 = 8.0;

  // Shadow definitions for each elevation level
  static List<BoxShadow> getShadowForElevation(double elevation) {
    if (elevation == 0) {
      return [];
    } else if (elevation <= 1) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (elevation <= 2) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (elevation <= 3) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (elevation <= 4) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (elevation <= 5) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.14),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    }
  }

  // Legacy shadow getters (for backward compatibility)
  static List<BoxShadow> get shadowSM => getShadowForElevation(1);
  static List<BoxShadow> get shadowMD => getShadowForElevation(2);
  static List<BoxShadow> get shadowLG => getShadowForElevation(4);
  static List<BoxShadow> get shadowXL => getShadowForElevation(5);

  // ========== Animation Durations ==========
  /// 100ms - Instant feedback (micro-interactions)
  static const Duration durationInstant = Duration(milliseconds: 100);
  
  /// 150ms - Fast interactions (hovers, simple feedback)
  static const Duration durationFast = Duration(milliseconds: 150);
  
  /// 200ms - Quick transitions
  static const Duration durationQuick = Duration(milliseconds: 200);
  
  /// 250ms - Medium transitions (content swaps, small entries)
  static const Duration durationMedium = Duration(milliseconds: 250);
  
  /// 300ms - Standard transitions
  static const Duration durationStandard = Duration(milliseconds: 300);
  
  /// 400ms - Slow transitions (page transitions, large entries)
  static const Duration durationSlow = Duration(milliseconds: 400);
  
  /// 600ms - Slower transitions (complex animations)
  static const Duration durationSlower = Duration(milliseconds: 600);

  // ========== Easing Curves ==========
  /// Standard easing for most movements
  static const Curve curveStandard = Curves.easeInOut;
  
  /// Premium ease-out (fastOutSlowIn) - recommended for most animations
  static const Curve curveEaseOut = Curves.fastOutSlowIn;
  
  /// Ease-out cubic - smooth entry
  static const Curve curveEaseOutCubic = Cubic(0.33, 1.0, 0.68, 1.0);
  
  /// Sharp entry for quick feedback
  static const Curve curveEnter = Cubic(0.0, 0.0, 0.2, 1.0);
  
  /// Smooth exit for removing elements
  static const Curve curveExit = Cubic(0.4, 0.0, 1.0, 1.0);
  
  /// Soft spring for organic feeling components
  static const Curve curveSpring = Cubic(0.175, 0.885, 0.32, 1.275);
  
  /// Decelerate - smooth slowdown
  static const Curve curveDecelerate = Curves.decelerate;
  
  /// Accelerate - smooth speedup
  static const Curve curveAccelerate = Curves.easeIn;

  // ========== Color Tokens (Semantic) ==========
  // These reference AppTheme colors but provide semantic naming
  
  /// Primary brand color
  static Color get colorPrimary => AppTheme.deepSlate;
  
  /// Primary accent color
  static Color get colorAccent => AppTheme.coralRed;
  
  /// Secondary accent color
  static Color get colorSecondary => AppTheme.constructionOrange;
  
  /// Success color
  static Color get colorSuccess => AppTheme.successGreen;
  
  /// Warning color
  static Color get colorWarning => AppTheme.warningAmber;
  
  /// Error color
  static Color get colorError => AppTheme.errorRed;
  
  /// Info color
  static Color get colorInfo => AppTheme.skyBlue;
  
  /// Surface color (cards, containers)
  static Color get colorSurface => AppTheme.surface;
  
  /// Elevated surface color
  static Color get colorSurfaceElevated => AppTheme.surfaceElevated;
  
  /// Background color
  static Color get colorBackground => AppTheme.background;
  
  /// Border color (light)
  static Color get colorBorder => AppTheme.borderLight;
  
  /// Border color (medium)
  static Color get colorBorderMedium => AppTheme.borderMedium;
  
  /// Divider color
  static Color get colorDivider => AppTheme.divider;
  
  /// Text primary color
  static Color get colorTextPrimary => AppTheme.textPrimary;
  
  /// Text secondary color
  static Color get colorTextSecondary => AppTheme.textSecondary;
  
  /// Text tertiary color
  static Color get colorTextTertiary => AppTheme.textTertiary;
  
  /// Text inverse color (white on dark)
  static Color get colorTextInverse => AppTheme.textInverse;
  
  /// Interactive color (for links, buttons)
  static Color get colorInteractive => AppTheme.coralRed;
  
  /// Interactive hover color
  static Color get colorInteractiveHover => AppTheme.coralRedDark;
  
  /// Disabled color
  static Color get colorDisabled => AppTheme.textTertiary.withOpacity(0.4);

  // ========== Touch Targets ==========
  /// Minimum touch target size (WCAG 2.2 AA requirement)
  static const double touchTargetMin = 44.0;
  
  /// Standard touch target size
  static const double touchTargetStandard = 48.0;
  
  /// Large touch target size
  static const double touchTargetLarge = 56.0;

  // ========== Z-Index Layers ==========
  /// Base layer
  static const int zIndexBase = 0;
  
  /// Elevated layer (cards)
  static const int zIndexElevated = 1;
  
  /// Dropdown layer
  static const int zIndexDropdown = 100;
  
  /// Sticky layer (headers)
  static const int zIndexSticky = 200;
  
  /// Overlay layer (modals, dialogs)
  static const int zIndexOverlay = 300;
  
  /// Tooltip layer
  static const int zIndexTooltip = 400;
  
  /// Maximum layer
  static const int zIndexMax = 999;

  // ========== Responsive Breakpoints ==========
  /// Mobile breakpoint (< 640px)
  static const double breakpointMobile = 640.0;
  
  /// Tablet breakpoint (640px - 1024px)
  static const double breakpointTablet = 768.0;
  
  /// Desktop breakpoint (>= 1024px)
  static const double breakpointDesktop = 1024.0;
  
  /// Wide desktop breakpoint (>= 1440px)
  static const double breakpointWide = 1440.0;
  
  /// Ultra-wide desktop breakpoint (>= 1920px)
  static const double breakpointUltraWide = 1920.0;
}
