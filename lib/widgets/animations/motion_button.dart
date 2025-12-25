import 'package:flutter/material.dart';
import '../../constants/app_motion.dart';

/// A wrapper for buttons that provides smooth hover and press feedback
/// Hover: Scales to 1.02
/// Press: Scales to 0.97
class MotionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double hoverScale;
  final double pressScale;
  final bool isEnabled;

  const MotionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.hoverScale = 1.02,
    this.pressScale = 0.97,
    this.isEnabled = true,
  });

  @override
  State<MotionButton> createState() => _MotionButtonState();
}

class _MotionButtonState extends State<MotionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed) {
      scale = widget.pressScale;
    } else if (_isHovered) {
      scale = widget.hoverScale;
    }

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: widget.isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: AppMotion.durationFast,
          curve: AppMotion.curveStandard,
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          child: Opacity(
            opacity: widget.isEnabled ? 1.0 : 0.6,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _setHover(bool value) {
    if (widget.isEnabled) {
      setState(() => _isHovered = value);
    }
  }

  void _setPressed(bool value) {
    if (widget.isEnabled) {
      setState(() => _isPressed = value);
    }
  }
}
