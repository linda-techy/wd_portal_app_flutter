import 'package:flutter/material.dart';

/// Centralized motion tokens for Walldot Builders
/// Standardizes durations and easing curves across the application
class AppMotion {
  // ========== Durations ==========
  
  /// Fast interactions (hovers, simple feedback) - 150ms
  static const Duration durationFast = Duration(milliseconds: 150);
  
  /// Medium transitions (content swaps, small entries) - 250ms
  static const Duration durationMedium = Duration(milliseconds: 250);
  
  /// Slow transitions (page transitions, large entries) - 400ms
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ========== Easing Curves ==========
  
  /// Standard easing for most movements
  static const Curve curveStandard = Curves.easeInOut;
  
  /// Sharp entry for quick feedback
  static const Curve curveEnter = Cubic(0.0, 0.0, 0.2, 1.0); // ease-out
  
  /// Smooth exit for removing elements
  static const Curve curveExit = Cubic(0.4, 0.0, 1.0, 1.0); // ease-in

  /// Soft spring for organic feeling components
  static const Curve curveSpring = Cubic(0.175, 0.885, 0.32, 1.275);
}
