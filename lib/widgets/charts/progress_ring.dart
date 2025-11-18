import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Progress Ring Chart - For budget utilization, completion percentage
class ProgressRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final String? valueLabel;
  final Color? color;
  final double size;
  final double strokeWidth;
  
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.valueLabel,
    this.color,
    this.size = 120,
    this.strokeWidth = 12,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryBlue;
    final percentage = (value * 100).toStringAsFixed(1);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  backgroundColor: AppTheme.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.borderLight),
                ),
              ),
              // Progress circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueLabel ?? '$percentage%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: effectiveColor,
                        ),
                  ),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Budget Utilization Widget
class BudgetUtilization extends StatelessWidget {
  final double used;
  final double total;
  final String label;
  final Color? color;
  
  const BudgetUtilization({
    super.key,
    required this.used,
    required this.total,
    required this.label,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final effectiveColor = color ?? 
        (percentage > 0.9 ? AppTheme.statusError :
         percentage > 0.75 ? AppTheme.statusWarning :
         AppTheme.statusSuccess);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Used: ${_formatCurrency(used)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Total: ${_formatCurrency(total)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '₹${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }
}

