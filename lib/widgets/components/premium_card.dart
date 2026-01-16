import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_motion.dart';

/// Premium Card Component
/// Enhanced card with hover states and proper elevation
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _elevationController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _elevationController = AnimationController(
      vsync: this,
      duration: AppMotion.getDuration(AppMotion.durationFast),
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? DesignTokens.elevation1,
      end: (widget.elevation ?? DesignTokens.elevation1) + 2,
    ).animate(CurvedAnimation(
      parent: _elevationController,
      curve: AppMotion.getCurve(AppMotion.curveEaseOut),
    ));
  }

  @override
  void dispose() {
    _elevationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _elevationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _elevationController.reverse();
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return Container(
            margin: widget.margin ?? const EdgeInsets.all(DesignTokens.spacingMD),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppTheme.surface,
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(DesignTokens.radiusLG),
              boxShadow: DesignTokens.getShadowForElevation(
                _isHovered ? _elevationAnimation.value : (widget.elevation ?? DesignTokens.elevation1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular(DesignTokens.radiusLG),
                child: Padding(
                  padding: widget.padding ??
                      const EdgeInsets.all(DesignTokens.spacingLG),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Elevated Card (with higher default elevation)
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const ElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: child,
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: DesignTokens.elevation2,
      backgroundColor: backgroundColor,
    );
  }
}

/// Surface Component (base surface without elevation)
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const Surface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(DesignTokens.spacingLG),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusMD),
      ),
      child: child,
    );
  }
}
