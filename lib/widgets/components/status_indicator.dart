import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Status Indicator Component
/// Displays status with color-coded badges and icons
class StatusIndicator extends StatefulWidget {
  final String label;
  final StatusType type;
  final bool showIcon;
  final bool compact;
  final bool pulse;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.type,
    this.showIcon = true,
    this.compact = false,
    this.pulse = false,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(widget.type);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? AppTheme.spacingSM : AppTheme.spacingMD,
        vertical: widget.compact ? AppTheme.spacingXS : AppTheme.spacingSM,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            ScaleTransition(
              scale: _pulseAnimation,
              child: Icon(
                config.icon,
                size: widget.compact ? 12 : 14,
                color: config.color,
              ),
            ),
            SizedBox(width: widget.compact ? 4 : 6),
          ],
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: config.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
  
  StatusConfig _getStatusConfig(StatusType type) {
    switch (type) {
      case StatusType.success:
        return StatusConfig(
          color: AppTheme.statusSuccess,
          backgroundColor: AppTheme.statusSuccessBg,
          borderColor: AppTheme.statusSuccess.withOpacity(0.3),
          icon: Icons.check_circle,
        );
      case StatusType.warning:
        return StatusConfig(
          color: AppTheme.statusWarning,
          backgroundColor: AppTheme.statusWarningBg,
          borderColor: AppTheme.statusWarning.withOpacity(0.3),
          icon: Icons.warning,
        );
      case StatusType.error:
        return StatusConfig(
          color: AppTheme.statusError,
          backgroundColor: AppTheme.statusErrorBg,
          borderColor: AppTheme.statusError.withOpacity(0.3),
          icon: Icons.error,
        );
      case StatusType.info:
        return StatusConfig(
          color: AppTheme.statusInfo,
          backgroundColor: AppTheme.statusInfoBg,
          borderColor: AppTheme.statusInfo.withOpacity(0.3),
          icon: Icons.info,
        );
      case StatusType.neutral:
        return StatusConfig(
          color: AppTheme.textSecondary,
          backgroundColor: AppTheme.surfaceElevated,
          borderColor: AppTheme.borderLight,
          icon: Icons.circle,
        );
      case StatusType.primary:
        return StatusConfig(
          color: AppTheme.primaryBlue,
          backgroundColor: AppTheme.statusInfoBg,
          borderColor: AppTheme.primaryBlue.withOpacity(0.3),
          icon: Icons.circle,
        );
    }
  }
}

enum StatusType {
  success,
  warning,
  error,
  info,
  neutral,
  primary,
}

class StatusConfig {
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  
  StatusConfig({
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

/// Project Status Indicator - Specialized for construction projects
class ProjectStatusIndicator extends StatelessWidget {
  final String status;
  final bool isOnTrack;
  final double? progress;
  
  const ProjectStatusIndicator({
    super.key,
    required this.status,
    this.isOnTrack = true,
    this.progress,
  });
  
  @override
  Widget build(BuildContext context) {
    final type = isOnTrack ? StatusType.success : StatusType.warning;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusIndicator(
          label: status,
          type: type,
        ),
        if (progress != null) ...[
          const SizedBox(height: AppTheme.spacingXS),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: progress! / 100,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOnTrack ? AppTheme.statusSuccess : AppTheme.statusWarning,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ],
    );
  }
}

