import 'package:flutter/material.dart';
import '../../constants/app_motion.dart';

/// Enhanced entrance animation for content blocks, cards, and list items
/// Provides a coordinated fade + slide-up effect with premium easing
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
      duration: AppMotion.getDuration(AppMotion.durationMedium),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.getCurve(AppMotion.curveEaseOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.getCurve(AppMotion.curveEaseOutCubic),
    ));

    Future.delayed(widget.delay, () {
      if (mounted && !AppMotion.shouldDisableAnimations()) {
        _controller.forward();
      } else if (mounted) {
        _controller.value = 1.0; // Skip animation if reduced motion
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
    if (AppMotion.shouldDisableAnimations()) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
