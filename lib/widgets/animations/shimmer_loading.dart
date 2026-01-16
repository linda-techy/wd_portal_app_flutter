import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_motion.dart';

/// Premium shimmer effect for skeleton loaders
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = DesignTokens.radiusMD,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.getDuration(const Duration(milliseconds: 1500)),
    );
    
    if (!AppMotion.shouldDisableAnimations()) {
      _controller.repeat();
    }

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.getCurve(Curves.easeInOutSine),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppTheme.surfaceElevated;
    final highlightColor = widget.highlightColor ?? AppTheme.surface;

    if (AppMotion.shouldDisableAnimations()) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(1.0 + _animation.value, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton Loader - Pre-built skeleton components
class SkeletonLoader extends StatelessWidget {
  final SkeletonType type;
  final double? width;
  final double? height;

  const SkeletonLoader({
    super.key,
    required this.type,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SkeletonType.text:
        return ShimmerLoading(
          width: width ?? double.infinity,
          height: height ?? 16,
        );
      case SkeletonType.title:
        return ShimmerLoading(
          width: width ?? 200,
          height: height ?? 24,
        );
      case SkeletonType.avatar:
        return ShimmerLoading(
          width: width ?? 40,
          height: height ?? 40,
          borderRadius: DesignTokens.radiusFull,
        );
      case SkeletonType.card:
        return ShimmerLoading(
          width: width ?? double.infinity,
          height: height ?? 200,
        );
      case SkeletonType.button:
        return ShimmerLoading(
          width: width ?? 120,
          height: height ?? 44,
        );
    }
  }
}

enum SkeletonType { text, title, avatar, card, button }

/// Premium Loading Spinner
class PremiumSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const PremiumSpinner({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.coralRed,
        ),
      ),
    );
  }
}
