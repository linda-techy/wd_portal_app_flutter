import 'package:flutter/material.dart';
import '../../constants/app_motion.dart';

/// Entrance animation for content blocks, cards, and list items
/// Provides a coordinated fade + slide-up effect
class EntranceAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double slideOffset;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideOffset = 30.0,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationMedium,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveEnter,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveStandard,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
