import 'package:flutter/material.dart';
import 'package:admin/models/project_stats.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';

class ProjectStatsWidget extends StatelessWidget {
  final ProjectStats stats;

  const ProjectStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Column(
        children: _buildStatCards(context),
      ),
      desktop: Row(
        children: _buildStatCards(context),
      ),
    );
  }

  List<Widget> _buildStatCards(BuildContext context) {
    return [
      Expanded(
        child: _StatCard(
          title: 'Total Projects',
          value: stats.totalProjects.toString(),
          icon: Icons.folder,
          color: AppTheme.primaryBlue,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD, height: AppTheme.spacingMD),
      Expanded(
        child: _StatCard(
          title: 'Active',
          value: stats.activeProjects.toString(),
          icon: Icons.trending_up,
          color: AppTheme.statusInfo,
          subtitle: '${stats.onTrackCount} on track',
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD, height: AppTheme.spacingMD),
      Expanded(
        child: _StatCard(
          title: 'Completed',
          value: stats.completedProjects.toString(),
          icon: Icons.check_circle,
          color: AppTheme.statusSuccess,
          subtitle: '${stats.completionRate.toStringAsFixed(1)}% rate',
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD, height: AppTheme.spacingMD),
      Expanded(
        child: _StatCard(
          title: 'Delayed',
          value: stats.delayedCount.toString(),
          icon: Icons.warning,
          color: stats.delayedCount > 0
              ? AppTheme.statusError
              : AppTheme.textSecondary,
        ),
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
