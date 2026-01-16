import 'package:flutter/material.dart';
import '../../constants/app_motion.dart';
import '../../theme/design_tokens.dart';

/// Enhanced wrapper for buttons that provides smooth hover and press feedback
/// Uses premium easing curves and respects reduced motion
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
    this.pressScale = 0.98,
    this.isEnabled = true,
  });

  @override
  State<MotionButton> createState() => _MotionButtonState();
}

class _MotionButtonState extends State<MotionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppMotion.getDuration(AppMotion.durationFast),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: AppMotion.getCurve(AppMotion.curveEaseOut),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_isPressed && !AppMotion.shouldDisableAnimations()) {
      scale = _scaleAnimation.value;
    } else if (_isHovered && !AppMotion.shouldDisableAnimations()) {
      scale = widget.hoverScale;
    }

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: widget.isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          _setPressed(true);
          if (!AppMotion.shouldDisableAnimations()) {
            _scaleController.forward();
          }
        },
        onTapUp: (_) {
          _setPressed(false);
          if (!AppMotion.shouldDisableAnimations()) {
            _scaleController.reverse();
          }
        },
        onTapCancel: () {
          _setPressed(false);
          if (!AppMotion.shouldDisableAnimations()) {
            _scaleController.reverse();
          }
        },
        onTap: widget.isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: AppMotion.getDuration(AppMotion.durationFast),
          curve: AppMotion.getCurve(AppMotion.curveEaseOut),
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          child: Opacity(
            opacity: widget.isEnabled ? 1.0 : DesignTokens.colorDisabled.opacity,
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
