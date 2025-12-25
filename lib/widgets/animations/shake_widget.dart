import 'package:flutter/material.dart';
import 'dart:math';

/// A widget that shakes horizontally to provide negative feedback (e.g., on form error)
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shouldShake;
  final Duration duration;
  final double offset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shouldShake = false,
    this.duration = const Duration(milliseconds: 400),
    this.offset = 6.0,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 4-cycle shake animation sequence
  double _getShakeOffset(double progress) {
    if (progress == 0) return 0;
    return sin(progress * pi * 4) * widget.offset * (1 - progress);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_getShakeOffset(_controller.value), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
