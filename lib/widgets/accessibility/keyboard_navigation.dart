import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/accessibility_utils.dart';

/// Keyboard Navigation Wrapper
/// Provides full keyboard navigation support with FocusTraversalGroup
class KeyboardNavigationWrapper extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    // Use FocusTraversalPolicy instead of custom shortcuts to preserve native tab behavior
    // This ensures proper tab navigation while still providing accessibility support
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(), // Use standard reading order for tab navigation
      child: child,
    );
  }
}

/// Intent for moving to next focus
class NextFocusIntent extends Intent {
  const NextFocusIntent();
}

/// Intent for moving to previous focus
class PreviousFocusIntent extends Intent {
  const PreviousFocusIntent();
}

/// Intent for activating focused widget
class ActivateIntent extends Intent {
  const ActivateIntent();
}

/// Action for next focus
class NextFocusAction extends Action<NextFocusIntent> {
  @override
  Object? invoke(NextFocusIntent intent) {
    final context = primaryFocus?.context;
    if (context != null) {
      AccessibilityUtils.moveFocusToNext(context);
    }
    return null;
  }
}

/// Action for previous focus
class PreviousFocusAction extends Action<PreviousFocusIntent> {
  @override
  Object? invoke(PreviousFocusIntent intent) {
    final context = primaryFocus?.context;
    if (context != null) {
      AccessibilityUtils.moveFocusToPrevious(context);
    }
    return null;
  }
}

/// Action for activating focused widget
class ActivateAction extends Action<ActivateIntent> {
  @override
  Object? invoke(ActivateIntent intent) {
    final node = primaryFocus;
    if (node != null && node.canRequestFocus) {
      // Trigger tap/activation
      // This is handled by the widget itself (buttons, etc.)
    }
    return null;
  }
}

/// Focus Trap for Modals
/// Traps focus within a modal/dialog
class FocusTrap extends StatelessWidget {
  final Widget child;
  final FocusNode? focusNode;

  const FocusTrap({
    super.key,
    required this.child,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: focusNode != null ? FocusScopeNode() : null,
      autofocus: true,
      child: child,
    );
  }
}
