import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_motion.dart';
import '../../utils/accessibility_utils.dart';

/// Premium Text Input
/// Enhanced TextField with animations, validation, and accessibility
class PremiumTextInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  const PremiumTextInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.semanticLabel,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<PremiumTextInput> createState() => _PremiumTextInputState();
}

class _PremiumTextInputState extends State<PremiumTextInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _helperController;
  late Animation<double> _helperAnimation;
  bool _isFocused = false;
  bool _hasError = false;
  bool _hasBeenTouched = false; // Track if user has interacted with the field

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _helperController = AnimationController(
      vsync: this,
      duration: AppMotion.getDuration(AppMotion.durationMedium),
    );
    _helperAnimation = CurvedAnimation(
      parent: _helperController,
      curve: AppMotion.getCurve(AppMotion.curveEaseOut),
    );

    if (widget.helperText != null || widget.errorText != null) {
      _helperController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _helperController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final wasFocused = _isFocused;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // Mark as touched when field gains focus
    if (!_hasBeenTouched && _isFocused) {
      setState(() {
        _hasBeenTouched = true;
      });
    }
  }

  void _validate(String? value, {bool force = false}) {
    // Only validate if field has been interacted with (has focus or has been blurred)
    if (widget.validator != null && (_isFocused || force)) {
      final error = widget.validator!(value);
      if (mounted) {
        setState(() {
          _hasError = error != null;
        });
      }
      if (_hasError && error != null) {
        AccessibilityUtils.announceError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show helper text if explicitly provided or if errorText is explicitly provided
    // We rely on TextFormField's built-in error display for validation errors
    final effectiveError = widget.errorText;
    final showHelper = widget.helperText != null || effectiveError != null;

    if (showHelper && _helperController.status != AnimationStatus.forward) {
      _helperController.forward();
    } else if (!showHelper &&
        _helperController.status != AnimationStatus.reverse) {
      _helperController.reverse();
    }

    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? widget.label ?? widget.hint,
      hint: widget.hint,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: (value) {
              widget.onChanged?.call(value);
              // Mark field as touched when user starts typing
              if (!_hasBeenTouched) {
                setState(() {
                  _hasBeenTouched = true;
                });
              }
              // Only validate while field is focused (user is typing) AND has an existing error
              if (_isFocused && _hasError) {
                // Trigger a form re-validation for this field only
                // Since we can't easily trigger standardFormField validation without form key,
                // we rely on the parent form or manual validation call.
                // However, we can manually check and update internal state for lazy clear.
                final error = widget.validator!(value);
                setState(() {
                  _hasError = error != null;
                });
                // If error is resolved, we want the TextFormField to clear its visual error.
                // The best way to do this in TextFormField is via form autovalidation or manual validate.
                // For now, let's at least update our internal state.
              }
            },
            onTap: () {
              // Mark field as touched when user taps on it
              if (!_hasBeenTouched) {
                setState(() {
                  _hasBeenTouched = true;
                });
              }
            },
            onEditingComplete: () {
              // Mark as touched when user finishes editing
              if (!_hasBeenTouched) {
                setState(() {
                  _hasBeenTouched = true;
                });
              }
              // Move to next field on desktop/web (Tab key) or mobile (Next button)
              if (widget.onFieldSubmitted == null) {
                FocusScope.of(context).nextFocus();
              }
            },
            onFieldSubmitted: widget.onFieldSubmitted,
            // Only validate when form is explicitly validated (on submit)
            // Don't validate on initial load - autovalidateMode is disabled
            validator: widget.validator != null
                ? (value) {
                    final error = widget.validator!(value);
                    // Sync internal state with framework validation result
                    if (mounted && _hasError != (error != null)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _hasError = error != null;
                          });
                        }
                      });
                    }
                    if (error != null) {
                      // Mark as touched when validation fails
                      if (!_hasBeenTouched) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _hasBeenTouched = true;
                            });
                          }
                        });
                      }
                    }
                    return error;
                  }
                : null,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            // Cross-platform text input action:
            // - Desktop/Web: Tab key moves to next field
            // - Mobile: Shows "Next" button on keyboard that moves to next field
            // - Last field: Shows "Done" button
            textInputAction: widget.onFieldSubmitted != null
                ? TextInputAction.done
                : TextInputAction.next,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeBodyMedium,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppTheme.coralRed)
                  : null,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor:
                  widget.enabled ? AppTheme.surface : AppTheme.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMD,
                vertical: DesignTokens.spacingMD,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.coralRed,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.errorRed,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.errorRed,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: DesignTokens.colorDisabled,
                  width: 1,
                ),
              ),
            ),
          ),
          if (showHelper)
            FadeTransition(
              opacity: _helperAnimation,
              child: SizeTransition(
                sizeFactor: _helperAnimation,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: DesignTokens.spacingXS,
                    left: DesignTokens.spacingMD,
                  ),
                  child: Text(
                    effectiveError ?? widget.helperText ?? '',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBodySmall,
                      color: effectiveError != null
                          ? AppTheme.errorRed
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium Password Input
class PremiumPasswordInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  const PremiumPasswordInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.semanticLabel,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<PremiumPasswordInput> createState() => _PremiumPasswordInputState();
}

class _PremiumPasswordInputState extends State<PremiumPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return PremiumTextInput(
      label: widget.label,
      hint: widget.hint,
      helperText: widget.helperText,
      errorText: widget.errorText,
      controller: widget.controller,
      onChanged: widget.onChanged,
      validator: widget.validator,
      obscureText: _obscureText,
      enabled: widget.enabled,
      prefixIcon: widget.prefixIcon ?? Icons.lock_outline,
      semanticLabel: widget.semanticLabel,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppTheme.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}

/// Premium Search Input
class PremiumSearchInput extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool enabled;

  const PremiumSearchInput({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTextInput(
      hint: hint ?? 'Search...',
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      prefixIcon: Icons.search,
      semanticLabel: 'Search',
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
              tooltip: 'Clear search',
            )
          : null,
    );
  }
}

/// Premium Text Area (Multi-line)
class PremiumTextArea extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final String? semanticLabel;
  final FocusNode? focusNode;

  const PremiumTextArea({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 4,
    this.maxLength,
    this.semanticLabel,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTextInput(
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
    );
  }
}

/// Premium Dropdown Input
class PremiumDropdownInput<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final String? semanticLabel;

  const PremiumDropdownInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.semanticLabel,
  });

  @override
  State<PremiumDropdownInput<T>> createState() =>
      _PremiumDropdownInputState<T>();
}

class _PremiumDropdownInputState<T> extends State<PremiumDropdownInput<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _helperController;
  late Animation<double> _helperAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _helperController = AnimationController(
      vsync: this,
      duration: AppMotion.getDuration(AppMotion.durationMedium),
    );
    _helperAnimation = CurvedAnimation(
      parent: _helperController,
      curve: AppMotion.getCurve(AppMotion.curveEaseOut),
    );

    if (widget.helperText != null || widget.errorText != null) {
      _helperController.forward();
    }
  }

  @override
  void dispose() {
    _helperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveError =
        widget.errorText ?? (_hasError ? 'Please select an option' : null);
    final showHelper = widget.helperText != null || effectiveError != null;

    if (showHelper && _helperController.status != AnimationStatus.forward) {
      _helperController.forward();
    } else if (!showHelper &&
        _helperController.status != AnimationStatus.reverse) {
      _helperController.reverse();
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label ?? widget.hint,
      hint: widget.hint,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<T>(
            value: widget.value,
            items: widget.items,
            onChanged: widget.enabled
                ? (value) {
                    widget.onChanged?.call(value);
                    if (widget.validator != null) {
                      final error = widget.validator!(value);
                      setState(() {
                        _hasError = error != null;
                      });
                      if (_hasError && error != null) {
                        AccessibilityUtils.announceError(context, error);
                      }
                    }
                  }
                : null,
            validator: widget.validator,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppTheme.coralRed)
                  : null,
              filled: true,
              fillColor:
                  widget.enabled ? AppTheme.surface : AppTheme.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMD,
                vertical: DesignTokens.spacingMD,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.coralRed,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.errorRed,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(
                  color: AppTheme.errorRed,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: DesignTokens.colorDisabled,
                  width: 1,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeBodyMedium,
              color: AppTheme.textPrimary,
            ),
          ),
          if (showHelper)
            FadeTransition(
              opacity: _helperAnimation,
              child: SizeTransition(
                sizeFactor: _helperAnimation,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: DesignTokens.spacingXS,
                    left: DesignTokens.spacingMD,
                  ),
                  child: Text(
                    effectiveError ?? widget.helperText ?? '',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBodySmall,
                      color: effectiveError != null
                          ? AppTheme.errorRed
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
