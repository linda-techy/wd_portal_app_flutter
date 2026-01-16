import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_motion.dart';
import '../../utils/accessibility_utils.dart';
import '../components/premium_button.dart';

/// Premium Modal Dialog
/// Full-screen overlay with backdrop blur and keyboard navigation
class PremiumModal extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final bool barrierDismissible;
  final Color? backgroundColor;
  final double? maxWidth;
  final String? semanticLabel;

  const PremiumModal({
    super.key,
    required this.child,
    this.title,
    this.showCloseButton = true,
    this.onClose,
    this.barrierDismissible = true,
    this.backgroundColor,
    this.maxWidth,
    this.semanticLabel,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    Color? backgroundColor,
    double? maxWidth,
    String? semanticLabel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => PremiumModal(
        child: child,
        title: title,
        showCloseButton: showCloseButton,
        onClose: () => Navigator.of(context).pop(),
        barrierDismissible: barrierDismissible,
        backgroundColor: backgroundColor,
        maxWidth: maxWidth,
        semanticLabel: semanticLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(DesignTokens.spacingLG),
      child: FocusScope(
        autofocus: true,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              if (barrierDismissible) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Semantics(
            dialog: true,
            label: semanticLabel ?? title ?? 'Dialog',
            child: Container(
              constraints: maxWidth != null
                  ? BoxConstraints(maxWidth: maxWidth!)
                  : const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: backgroundColor ?? AppTheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                boxShadow: DesignTokens.getShadowForElevation(DesignTokens.elevation5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null || showCloseButton)
                    Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacingLG),
                      child: Row(
                        children: [
                          if (title != null)
                            Expanded(
                              child: Text(
                                title!,
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeHeadlineMedium,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          if (showCloseButton)
                            PremiumIconButton(
                              icon: Icons.close,
                              onPressed: onClose ?? () => Navigator.of(context).pop(),
                              semanticLabel: 'Close dialog',
                            ),
                        ],
                      ),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        DesignTokens.spacingLG,
                        title != null || showCloseButton ? 0 : DesignTokens.spacingLG,
                        DesignTokens.spacingLG,
                        DesignTokens.spacingLG,
                      ),
                      child: child,
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

/// Premium Bottom Sheet
class PremiumBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final bool isDismissible;
  final Color? backgroundColor;
  final String? semanticLabel;

  const PremiumBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showCloseButton = true,
    this.onClose,
    this.isDismissible = true,
    this.backgroundColor,
    this.semanticLabel,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showCloseButton = true,
    bool isDismissible = true,
    Color? backgroundColor,
    String? semanticLabel,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumBottomSheet(
        child: child,
        title: title,
        showCloseButton: showCloseButton,
        onClose: () => Navigator.of(context).pop(),
        isDismissible: isDismissible,
        backgroundColor: backgroundColor,
        semanticLabel: semanticLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLG),
            ),
            boxShadow: DesignTokens.getShadowForElevation(DesignTokens.elevation5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null || showCloseButton)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLG,
                    vertical: DesignTokens.spacingMD,
                  ),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeHeadlineMedium,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      if (showCloseButton)
                        PremiumIconButton(
                          icon: Icons.close,
                          onPressed: onClose ?? () => Navigator.of(context).pop(),
                          semanticLabel: 'Close bottom sheet',
                        ),
                    ],
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.spacingLG,
                    title != null || showCloseButton ? 0 : DesignTokens.spacingLG,
                    DesignTokens.spacingLG,
                    MediaQuery.of(context).viewInsets.bottom + DesignTokens.spacingLG,
                  ),
                  child: Semantics(
                    label: semanticLabel ?? title ?? 'Bottom sheet',
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enhanced Drawer
class PremiumDrawer extends StatelessWidget {
  final Widget child;
  final String? title;
  final double? width;
  final Color? backgroundColor;

  const PremiumDrawer({
    super.key,
    required this.child,
    this.title,
    this.width,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: width ?? 280,
      backgroundColor: backgroundColor ?? AppTheme.surface,
      child: Column(
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingLG),
              decoration: BoxDecoration(
                color: AppTheme.deepSlate,
                boxShadow: DesignTokens.getShadowForElevation(DesignTokens.elevation1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeHeadlineMedium,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textInverse,
                      ),
                    ),
                  ),
                  PremiumIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textInverse,
                    semanticLabel: 'Close drawer',
                  ),
                ],
              ),
            ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
