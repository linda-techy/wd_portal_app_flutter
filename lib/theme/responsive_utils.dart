import 'package:flutter/material.dart';

/// Enhanced Responsive Utilities for Construction Admin Portal
/// Supports desktop, tablet, and mobile layouts with breakpoints optimized for data-heavy interfaces
class ResponsiveUtils {
  // Breakpoints optimized for admin portals
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  static const double largeDesktopBreakpoint = 1920;
  
  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  
  // Get responsive value based on screen size
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    }
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }
  
  // Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        largeDesktop: 48.0,
      ),
      vertical: responsiveValue(
        context: context,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
        largeDesktop: 24.0,
      ),
    );
  }
  
  // Get responsive column count for grids
  static int responsiveColumnCount(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }
  
  // Get responsive font size
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }
  
  // Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  
  // Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  
  // Check if in landscape mode
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
  
  // Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;
}

/// Responsive Layout Builder Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? largeDesktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop!;
    }
    if (ResponsiveUtils.isDesktop(context)) {
      return desktop;
    }
    if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Adaptive Container that adjusts based on screen size
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;
  
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? ResponsiveUtils.responsivePadding(context);
    final effectiveMaxWidth = maxWidth ?? 
        ResponsiveUtils.responsiveValue<double>(
          context: context,
          mobile: double.infinity,
          tablet: 1200.0,
          desktop: 1400.0,
          largeDesktop: 1600.0,
        );
    
    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );
    
    if (centerContent && maxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    }
    
    return content;
  }
}

