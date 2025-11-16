import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

/// Utility class for consistent container styling across the app
class ContainerStyles {
  // Private constructor to prevent instantiation
  ContainerStyles._();

  /// Default container decoration with light blue background
  static BoxDecoration get defaultContainer => BoxDecoration(
        color: boxPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: containerShadow,
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Card container decoration with white background and blue accent
  static BoxDecoration get cardContainer => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: containerShadow,
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Primary blue container
  static BoxDecoration get primaryBox => BoxDecoration(
        color: boxPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Secondary gray container
  static BoxDecoration get secondaryBox => BoxDecoration(
        color: boxGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderSecondary, width: 2),
        boxShadow: [
          BoxShadow(
            color: containerShadow,
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Success green container
  static BoxDecoration get successBox => BoxDecoration(
        color: boxSuccess,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderSuccess, width: 2),
        boxShadow: [
          BoxShadow(
            color: successColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Warning amber container
  static BoxDecoration get warningBox => BoxDecoration(
        color: boxWarning,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderWarning, width: 2),
        boxShadow: [
          BoxShadow(
            color: warningColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Error red container
  static BoxDecoration get errorBox => BoxDecoration(
        color: boxError,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderError, width: 2),
        boxShadow: [
          BoxShadow(
            color: errorColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Info indigo container
  static BoxDecoration get infoBox => BoxDecoration(
        color: boxInfo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderInfo, width: 2),
        boxShadow: [
          BoxShadow(
            color: infoColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Purple container
  static BoxDecoration get purpleBox => BoxDecoration(
        color: boxPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: containerShadow,
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Elevated container decoration with stronger shadow
  static BoxDecoration get elevatedContainer => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: containerBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: containerShadow,
            spreadRadius: 0,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Subtle container decoration for secondary content
  static BoxDecoration get subtleContainer => BoxDecoration(
        color: containerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: containerBorder.withOpacity(0.5), width: 1),
      );

  /// Primary accent container decoration
  static BoxDecoration get primaryContainer => BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      );

  /// Success container decoration
  static BoxDecoration get successContainer => BoxDecoration(
        color: successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.2), width: 1),
      );

  /// Warning container decoration
  static BoxDecoration get warningContainer => BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withOpacity(0.2), width: 1),
      );

  /// Error container decoration
  static BoxDecoration get errorContainer => BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withOpacity(0.2), width: 1),
      );

  /// Info container decoration
  static BoxDecoration get infoContainer => BoxDecoration(
        color: infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: infoColor.withOpacity(0.2), width: 1),
      );

  /// Gradient container decoration
  static BoxDecoration get gradientContainer => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            containerBackground,
            containerBackground.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: containerBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: containerShadow,
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Get container decoration based on type
  static BoxDecoration getContainerDecoration(ContainerType type) {
    switch (type) {
      case ContainerType.defaultType:
        return defaultContainer;
      case ContainerType.card:
        return cardContainer;
      case ContainerType.elevated:
        return elevatedContainer;
      case ContainerType.subtle:
        return subtleContainer;
      case ContainerType.primary:
        return primaryBox;
      case ContainerType.secondary:
        return secondaryBox;
      case ContainerType.success:
        return successBox;
      case ContainerType.warning:
        return warningBox;
      case ContainerType.error:
        return errorBox;
      case ContainerType.info:
        return infoBox;
      case ContainerType.purple:
        return purpleBox;
      case ContainerType.gradient:
        return gradientContainer;
    }
  }
}

/// Enum for different container types
enum ContainerType {
  defaultType,
  card,
  elevated,
  subtle,
  primary,
  secondary,
  success,
  warning,
  error,
  info,
  purple,
  gradient,
}

/// Helper widget for consistent container styling
class StyledContainer extends StatelessWidget {
  final Widget child;
  final ContainerType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;

  const StyledContainer({
    super.key,
    required this.child,
    this.type = ContainerType.defaultType,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(defaultPadding),
      decoration: decoration ?? ContainerStyles.getContainerDecoration(type),
      child: child,
    );
  }
}
