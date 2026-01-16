import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Premium Motion System for Walldot Builders
/// Standardizes durations, easing curves, and reduced motion support
class AppMotion {
  // ========== Durations ==========
  
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

  // ========== Premium Easing Curves ==========
  
  /// Standard easing for most movements
  static const Curve curveStandard = Curves.easeInOut;
  
  /// Premium ease-out (fastOutSlowIn) - recommended for most animations
  static const Curve curveEaseOut = Curves.fastOutSlowIn;
  
  /// Ease-out cubic - smooth entry (premium feel)
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

  // ========== Spring Physics ==========
  
  /// Spring configuration for natural motion
  static const SpringDescription springDefault = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 30.0,
  );
  
  /// Light spring for subtle animations
  static const SpringDescription springLight = SpringDescription(
    mass: 0.8,
    stiffness: 400.0,
    damping: 25.0,
  );
  
  /// Heavy spring for dramatic animations
  static const SpringDescription springHeavy = SpringDescription(
    mass: 1.2,
    stiffness: 600.0,
    damping: 35.0,
  );

  // ========== Reduced Motion Support ==========
  
  /// Check if reduced motion is enabled (respects user preferences)
  static bool get isReducedMotionEnabled {
    return SchedulerBinding.instance.platformDispatcher.accessibilityFeatures
        .disableAnimations;
  }
  
  /// Get duration respecting reduced motion preferences
  static Duration getDuration(Duration normalDuration) {
    if (isReducedMotionEnabled) {
      return Duration.zero;
    }
    return normalDuration;
  }
  
  /// Get curve respecting reduced motion preferences
  static Curve getCurve(Curve normalCurve) {
    if (isReducedMotionEnabled) {
      return Curves.linear;
    }
    return normalCurve;
  }
  
  /// Check if animations should be disabled
  static bool shouldDisableAnimations() {
    return isReducedMotionEnabled;
  }

  // ========== Animation Presets ==========
  
  /// Fade animation preset
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: getCurve(curveEaseOut),
    );
  }
  
  /// Slide animation preset (from bottom)
  static Animation<Offset> createSlideUpAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: getCurve(curveEaseOutCubic),
    ));
  }
  
  /// Slide animation preset (from right)
  static Animation<Offset> createSlideRightAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: getCurve(curveEaseOutCubic),
    ));
  }
  
  /// Scale animation preset
  static Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: getCurve(curveEaseOutCubic),
    ));
  }
}
