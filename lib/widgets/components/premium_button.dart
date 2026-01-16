import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_motion.dart';
import '../../utils/accessibility_utils.dart';

/// Premium Primary Button
/// Full-featured primary action button with animations and accessibility
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double? minWidth;
  final String? semanticLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.minWidth,
    this.semanticLabel,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveLabel = widget.semanticLabel ?? widget.label;

    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: isEnabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: isEnabled ? (_) {
            setState(() => _isPressed = true);
            _scaleController.forward();
          } : null,
          onTapUp: isEnabled ? (_) {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          } : null,
          onTapCancel: isEnabled ? () {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          } : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? _scaleAnimation.value : (_isHovered ? 1.02 : 1.0),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: widget.minWidth ?? (widget.fullWidth ? double.infinity : 0),
                    minHeight: DesignTokens.touchTargetMin,
                  ),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? (_isHovered ? AppTheme.coralRedDark : AppTheme.coralRed)
                        : DesignTokens.colorDisabled,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    boxShadow: _isHovered && isEnabled
                        ? DesignTokens.getShadowForElevation(DesignTokens.elevation2)
                        : DesignTokens.getShadowForElevation(DesignTokens.elevation0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isEnabled ? widget.onPressed : null,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingLG,
                          vertical: DesignTokens.spacingMD,
                        ),
                        child: Row(
                          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isLoading)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.textInverse,
                                  ),
                                ),
                              )
                            else if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: 18,
                                color: AppTheme.textInverse,
                              ),
                              const SizedBox(width: DesignTokens.spacingSM),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: AppTheme.textInverse,
                                fontSize: DesignTokens.fontSizeLabelLarge,
                                fontWeight: FontWeight.w600,
                                letterSpacing: DesignTokens.letterSpacingWide,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Premium Secondary Button (Outlined)
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double? minWidth;
  final String? semanticLabel;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.minWidth,
    this.semanticLabel,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveLabel = widget.semanticLabel ?? widget.label;

    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: isEnabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: isEnabled ? (_) {
            setState(() => _isPressed = true);
            _scaleController.forward();
          } : null,
          onTapUp: isEnabled ? (_) {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          } : null,
          onTapCancel: isEnabled ? () {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          } : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? _scaleAnimation.value : (_isHovered ? 1.02 : 1.0),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: widget.minWidth ?? (widget.fullWidth ? double.infinity : 0),
                    minHeight: DesignTokens.touchTargetMin,
                  ),
                  decoration: BoxDecoration(
                    color: _isHovered && isEnabled
                        ? AppTheme.deepSlate.withOpacity(0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    border: Border.all(
                      color: isEnabled
                          ? AppTheme.deepSlate
                          : DesignTokens.colorDisabled,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isEnabled ? widget.onPressed : null,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingLG,
                          vertical: DesignTokens.spacingMD,
                        ),
                        child: Row(
                          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isLoading)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.deepSlate,
                                  ),
                                ),
                              )
                            else if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: 18,
                                color: isEnabled ? AppTheme.deepSlate : DesignTokens.colorDisabled,
                              ),
                              const SizedBox(width: DesignTokens.spacingSM),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: isEnabled ? AppTheme.deepSlate : DesignTokens.colorDisabled,
                                fontSize: DesignTokens.fontSizeLabelLarge,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Premium Ghost Button (Minimal)
class GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final String? semanticLabel;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.semanticLabel,
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveLabel = widget.semanticLabel ?? widget.label;

    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: isEnabled,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMD,
                vertical: DesignTokens.spacingSM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.deepSlate,
                        ),
                      ),
                    )
                  else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: isEnabled ? AppTheme.deepSlate : DesignTokens.colorDisabled,
                    ),
                    const SizedBox(width: DesignTokens.spacingSM),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: isEnabled ? AppTheme.deepSlate : DesignTokens.colorDisabled,
                      fontSize: DesignTokens.fontSizeLabelLarge,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Danger Button (Destructive actions)
class DangerButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final String? semanticLabel;

  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.semanticLabel,
  });

  @override
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveLabel = widget.semanticLabel ?? widget.label;

    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: isEnabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: isEnabled ? (_) {
            setState(() => _isPressed = true);
            _scaleController.forward();
          } : null,
          onTapUp: isEnabled ? (_) {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          } : null,
          onTapCancel: isEnabled ? () {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          } : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? _scaleAnimation.value : (_isHovered ? 1.02 : 1.0),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: widget.fullWidth ? double.infinity : 0,
                    minHeight: DesignTokens.touchTargetMin,
                  ),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? (_isHovered ? AppTheme.errorRed.withOpacity(0.9) : AppTheme.errorRed)
                        : DesignTokens.colorDisabled,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    boxShadow: _isHovered && isEnabled
                        ? DesignTokens.getShadowForElevation(DesignTokens.elevation2)
                        : DesignTokens.getShadowForElevation(DesignTokens.elevation0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isEnabled ? widget.onPressed : null,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingLG,
                          vertical: DesignTokens.spacingMD,
                        ),
                        child: Row(
                          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isLoading)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.textInverse,
                                  ),
                                ),
                              )
                            else if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: 18,
                                color: AppTheme.textInverse,
                              ),
                              const SizedBox(width: DesignTokens.spacingSM),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: AppTheme.textInverse,
                                fontSize: DesignTokens.fontSizeLabelLarge,
                                fontWeight: FontWeight.w600,
                                letterSpacing: DesignTokens.letterSpacingWide,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Premium Icon Button
class PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final Color? color;
  final double size;

  const PremiumIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.color,
    this.size = DesignTokens.touchTargetMin,
  });

  @override
  State<PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<PremiumIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final effectiveLabel = widget.semanticLabel ??
        AccessibilityUtils.getIconButtonLabel(widget.icon, label: widget.tooltip);
    final iconColor = widget.color ?? AppTheme.textPrimary;

    return Semantics(
      button: true,
      label: effectiveLabel,
      enabled: isEnabled,
      tooltip: widget.tooltip ?? effectiveLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
          child: Transform.scale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _isHovered && isEnabled
                    ? iconColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? widget.onPressed : null,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  child: Icon(
                    widget.icon,
                    color: isEnabled ? iconColor : DesignTokens.colorDisabled,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
