import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

/// Semantic Button Wrapper
/// Provides proper semantic structure for buttons
class SemanticButton extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const SemanticButton({
    super.key,
    required this.child,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: child,
    );
  }
}

/// Semantic Form Field Wrapper
class SemanticFormField extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final String? errorText;
  final bool enabled;

  const SemanticFormField({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = errorText != null && errorText!.isNotEmpty
        ? '$label. Error: $errorText'
        : label;
    return Semantics(
      textField: true,
      label: effectiveLabel,
      hint: hint,
      enabled: enabled,
      child: child,
    );
  }
}

/// Semantic Icon Button Wrapper
class SemanticIconButton extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;

  const SemanticIconButton({
    super.key,
    required this.child,
    required this.icon,
    this.label,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? AccessibilityUtils.getIconButtonLabel(icon);
    
    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: enabled,
      child: child,
    );
  }
}

/// Error Announcement Helper
class ErrorAnnouncement extends StatelessWidget {
  final Widget child;
  final String? errorText;
  final BuildContext context;

  const ErrorAnnouncement({
    super.key,
    required this.child,
    this.errorText,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AccessibilityUtils.announceError(this.context, errorText!);
      });
    }
    return child;
  }
}

/// Live Region for Dynamic Content
class LiveRegion extends StatelessWidget {
  final Widget child;
  final String? announcement;

  const LiveRegion({
    super.key,
    required this.child,
    this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: announcement != null
          ? Semantics(
              label: announcement,
              child: child,
            )
          : child,
    );
  }
}
