import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_motion.dart';
import '../theme/design_tokens.dart';

/// Accessibility Utilities
/// Provides WCAG 2.2 AA compliance helpers and accessibility features
class AccessibilityUtils {
  // ========== Reduced Motion Detection ==========
  
  /// Check if reduced motion is enabled
  static bool get isReducedMotionEnabled => AppMotion.isReducedMotionEnabled;
  
  /// Check if animations should be disabled
  static bool shouldDisableAnimations() => AppMotion.shouldDisableAnimations();

  // ========== Contrast Checking ==========
  
  /// Calculate relative luminance (WCAG formula)
  static double _getRelativeLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    
    final rsRGB = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    final gsRGB = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    final bsRGB = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();
    
    return 0.2126 * rsRGB + 0.7152 * gsRGB + 0.0722 * bsRGB;
  }
  
  /// Calculate contrast ratio between two colors
  static double getContrastRatio(Color color1, Color color2) {
    final l1 = _getRelativeLuminance(color1);
    final l2 = _getRelativeLuminance(color2);
    
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Check if contrast meets WCAG 2.2 AA standard (4.5:1 for normal text, 3:1 for large text)
  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }
  
  /// Check if contrast meets WCAG 2.2 AAA standard (7:1 for normal text, 4.5:1 for large text)
  static bool meetsWCAGAAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return isLargeText ? ratio >= 4.5 : ratio >= 7.0;
  }
  
  /// Get accessible text color for a given background
  static Color getAccessibleTextColor(Color backgroundColor) {
    const lightText = Colors.white;
    const darkText = Colors.black87;
    
    final lightRatio = getContrastRatio(lightText, backgroundColor);
    final darkRatio = getContrastRatio(darkText, backgroundColor);
    
    return lightRatio > darkRatio ? lightText : darkText;
  }

  // ========== Screen Reader Utilities ==========
  
  /// Announce message to screen readers
  static void announceToScreenReader(BuildContext context, String message) {
    // SemanticsService is deprecated. Use Semantics widget with liveRegion instead.
    // For now, we'll use ScaffoldMessenger for user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Announce error to screen readers
  static void announceError(BuildContext context, String errorMessage) {
    announceToScreenReader(context, 'Error: $errorMessage');
  }
  
  /// Announce success to screen readers
  static void announceSuccess(BuildContext context, String message) {
    announceToScreenReader(context, 'Success: $message');
  }

  // ========== Focus Management ==========
  
  /// Request focus on a widget
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }
  
  /// Unfocus current focus
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  /// Move focus to next widget
  static void moveFocusToNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }
  
  /// Move focus to previous widget
  static void moveFocusToPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }
  
  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // ========== Touch Target Helpers ==========
  
  /// Ensure minimum touch target size (WCAG 2.2 AA requirement: 44x44px)
  static Widget ensureMinimumTouchTarget(Widget child, {double? minSize}) {
    final size = minSize ?? DesignTokens.touchTargetMin;
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    );
  }
  
  /// Get minimum touch target size
  static double getMinimumTouchTarget() => DesignTokens.touchTargetMin;

  // ========== Semantic Helpers ==========
  
  /// Create semantic label for icon button
  static String getIconButtonLabel(IconData icon, {String? label}) {
    return label ?? _getIconName(icon);
  }
  
  /// Get readable icon name
  static String _getIconName(IconData icon) {
    // Common icon names for screen readers
    final iconNames = <IconData, String>{
      Icons.add: 'Add',
      Icons.edit: 'Edit',
      Icons.delete: 'Delete',
      Icons.close: 'Close',
      Icons.check: 'Check',
      Icons.search: 'Search',
      Icons.menu: 'Menu',
      Icons.more_vert: 'More options',
      Icons.arrow_back: 'Back',
      Icons.arrow_forward: 'Forward',
      Icons.settings: 'Settings',
      Icons.home: 'Home',
      Icons.person: 'Profile',
      Icons.notifications: 'Notifications',
    };
    
    return iconNames[icon] ?? 'Button';
  }
}
