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
    final normalized = phase.toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'PLANNING':
        return _PhaseInfo(
          displayName: 'Planning',
          color: AppTheme.statusInfo,
          icon: Icons.calculate,
        );
      case 'DESIGN':
        return _PhaseInfo(
          displayName: 'Design',
          color: AppTheme.primaryBlue,
          icon: Icons.design_services,
        );
      case 'CONSTRUCTION':
        return _PhaseInfo(
          displayName: 'Construction',
          color: AppTheme.statusWarning,
          icon: Icons.construction,
        );
      case 'COMPLETED':
        return _PhaseInfo(
          displayName: 'Completed',
          color: AppTheme.statusSuccess,
          icon: Icons.check_circle,
        );
      case 'ON_HOLD':
        return _PhaseInfo(
          displayName: 'On Hold',
          color: AppTheme.coralRed,
          icon: Icons.pause_circle_filled,
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
