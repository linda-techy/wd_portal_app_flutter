import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable Data Card Component
/// Optimized for displaying metrics, KPIs, and summary information
class DataCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? value;
  final String? valueText;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsets? padding;
  final bool showBorder;
  final Color? borderColor;
  
  const DataCard({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.valueText,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.trailing,
    this.padding,
    this.showBorder = true,
    this.borderColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppTheme.borderLight,
                width: 1,
              )
            : null,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and Icon
              Expanded(
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingSM),
                        decoration: BoxDecoration(
                          color: (iconColor ?? AppTheme.primaryBlue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: iconColor ?? AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          
          // Value Section
          if (value != null || valueText != null) ...[
            const SizedBox(height: AppTheme.spacingMD),
            value ??
                Text(
                  valueText!,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          ],
        ],
      ),
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: card,
      );
    }
    
    return card;
  }
}

/// Metric Card - Specialized for displaying KPIs
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool isPositive;
  final IconData? icon;
  final Color? accentColor;
  
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.isPositive = true,
    this.icon,
    this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryBlue;
    
    return DataCard(
      title: label,
      valueText: value,
      icon: icon,
      iconColor: color,
      trailing: change != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: (isPositive ? AppTheme.statusSuccess : AppTheme.statusError)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: isPositive ? AppTheme.statusSuccess : AppTheme.statusError,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    change!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isPositive ? AppTheme.statusSuccess : AppTheme.statusError,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

