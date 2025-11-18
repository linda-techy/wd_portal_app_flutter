import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Chart Card Wrapper
/// Provides consistent styling and layout for charts
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final Widget? legend;
  final List<Widget>? actions;
  final double? height;
  final EdgeInsets? padding;
  
  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.legend,
    this.actions,
    this.height,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Chart
          SizedBox(
            height: height ?? 300,
            child: chart,
          ),
          
          // Legend
          if (legend != null) ...[
            const SizedBox(height: AppTheme.spacingMD),
            legend!,
          ],
        ],
      ),
    );
  }
}


