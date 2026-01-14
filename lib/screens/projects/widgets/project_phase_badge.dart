import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';

class ProjectPhaseBadge extends StatelessWidget {
  final String phase;
  final bool compact;

  const ProjectPhaseBadge({
    super.key,
    required this.phase,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final phaseInfo = _getPhaseInfo(phase);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: phaseInfo.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: phaseInfo.color, width: 1),
        ),
        child: Text(
          phaseInfo.displayName,
          style: TextStyle(
            color: phaseInfo.color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: phaseInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: phaseInfo.color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            phaseInfo.icon,
            color: phaseInfo.color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            phaseInfo.displayName,
            style: TextStyle(
              color: phaseInfo.color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _PhaseInfo _getPhaseInfo(String phase) {
    final phaseUpper = phase.toUpperCase();
    
    switch (phaseUpper) {
      case 'DESIGN':
        return _PhaseInfo(
          displayName: 'Design',
          color: AppTheme.primaryBlue,
          icon: Icons.design_services,
        );
      case 'PLANNING':
        return _PhaseInfo(
          displayName: 'Planning',
          color: AppTheme.statusInfo,
          icon: Icons.calculate,
        );
      case 'EXECUTION':
        return _PhaseInfo(
          displayName: 'Execution',
          color: AppTheme.statusWarning,
          icon: Icons.construction,
        );
      case 'COMPLETION':
        return _PhaseInfo(
          displayName: 'Completion',
          color: AppTheme.coralRed,
          icon: Icons.check_circle_outline,
        );
      case 'HANDOVER':
        return _PhaseInfo(
          displayName: 'Handover',
          color: AppTheme.statusSuccess,
          icon: Icons.handshake,
        );
      case 'WARRANTY':
        return _PhaseInfo(
          displayName: 'Warranty',
          color: AppTheme.primaryColor,
          icon: Icons.verified_user,
        );
      default:
        return _PhaseInfo(
          displayName: phase,
          color: AppTheme.textSecondary,
          icon: Icons.circle,
        );
    }
  }
}

class _PhaseInfo {
  final String displayName;
  final Color color;
  final IconData icon;

  _PhaseInfo({
    required this.displayName,
    required this.color,
    required this.icon,
  });
}

