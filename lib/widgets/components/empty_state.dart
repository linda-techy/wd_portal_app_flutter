import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../components/premium_button.dart';

/// Professional Empty State Component
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing3XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(
                icon,
                size: 64,
                color: AppTheme.textTertiary,
              ),
            const SizedBox(height: DesignTokens.spacingLG),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeHeadlineMedium,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: DesignTokens.spacingSM),
              Text(
                message!,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBodyMedium,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spacingXL),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
