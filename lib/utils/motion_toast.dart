import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../constants/app_motion.dart';
import '../utils/accessibility_utils.dart';

/// Toast variant types
enum ToastVariant { success, error, warning, info }

/// Toast position
enum ToastPosition { top, bottom, center }

/// Enhanced professional motion-driven toast notification
class MotionToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastVariant variant = ToastVariant.success,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false, // Legacy support
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    // Map legacy isError to variant
    final effectiveVariant = isError ? ToastVariant.error : variant;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        variant: effectiveVariant,
        position: position,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
    
    // Announce to screen readers
    AccessibilityUtils.announceToScreenReader(context, message);
  }

  // Convenience methods
  static void showSuccess(
    BuildContext context, {
    required String message,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, variant: ToastVariant.success, position: position, duration: duration);
  }

  static void showError(
    BuildContext context, {
    required String message,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message: message, variant: ToastVariant.error, position: position, duration: duration);
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, variant: ToastVariant.warning, position: position, duration: duration);
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, variant: ToastVariant.info, position: position, duration: duration);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastVariant variant;
  final ToastPosition position;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.variant,
    required this.position,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  Color get _backgroundColor {
    switch (widget.variant) {
      case ToastVariant.success:
        return AppTheme.successGreen;
      case ToastVariant.error:
        return AppTheme.errorRed;
      case ToastVariant.warning:
        return AppTheme.warningAmber;
      case ToastVariant.info:
        return AppTheme.skyBlue;
    }
  }

  IconData get _icon {
    switch (widget.variant) {
      case ToastVariant.success:
        return Icons.check_circle_outline;
      case ToastVariant.error:
        return Icons.error_outline;
      case ToastVariant.warning:
        return Icons.warning_amber_outlined;
      case ToastVariant.info:
        return Icons.info_outline;
    }
  }

  Offset get _slideBegin {
    switch (widget.position) {
      case ToastPosition.top:
        return const Offset(0, -1);
      case ToastPosition.bottom:
        return const Offset(0, 1);
      case ToastPosition.center:
        return Offset.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.getDuration(AppMotion.durationMedium),
    );

    _offsetAnimation = Tween<Offset>(
      begin: _slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.getCurve(AppMotion.curveEaseOutCubic),
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.getCurve(AppMotion.curveEaseOut),
    );

    _controller.forward();

    // Auto-dismiss logic
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget positionedWidget;

    if (widget.position == ToastPosition.top) {
      positionedWidget = Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: _buildToastContent(),
      );
    } else if (widget.position == ToastPosition.bottom) {
      positionedWidget = Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: _buildToastContent(),
      );
    } else {
      positionedWidget = Center(
        child: _buildToastContent(),
      );
    }

    return positionedWidget;
  }

  Widget _buildToastContent() {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMD,
                vertical: DesignTokens.spacingMD,
              ),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                boxShadow: DesignTokens.getShadowForElevation(DesignTokens.elevation4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.spacingSM),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: DesignTokens.fontSizeBodyMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    const SizedBox(width: DesignTokens.spacingMD),
                    TextButton(
                      onPressed: () {
                        widget.onAction?.call();
                        _controller.reverse().then((_) => widget.onDismiss());
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingSM,
                          vertical: DesignTokens.spacingXS,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: DesignTokens.fontSizeBodySmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
