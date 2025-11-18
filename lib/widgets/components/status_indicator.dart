import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Status Indicator Component
/// Displays status with color-coded badges and icons
class StatusIndicator extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool showIcon;
  final bool compact;
  
  const StatusIndicator({
    super.key,
    required this.label,
    required this.type,
    this.showIcon = true,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(type);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spacingSM : AppTheme.spacingMD,
        vertical: compact ? AppTheme.spacingXS : AppTheme.spacingSM,
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
          if (showIcon) ...[
            Icon(
              config.icon,
              size: compact ? 12 : 14,
              color: config.color,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            label,
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

