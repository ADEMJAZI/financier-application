import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Premium styled button with native implicit animations and RTL support
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bgColor;
    Color fgColor;
    BorderSide? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = isDisabled ? colorScheme.primary.withOpacity(0.5) : colorScheme.primary;
        fgColor = colorScheme.onPrimary;
        if (!isDisabled && !_isPressed) {
          shadows = AppSpacing.shadowMd(bgColor);
        }
        break;
      case AppButtonVariant.secondary:
        bgColor = Colors.transparent;
        fgColor = isDisabled ? colorScheme.primary.withOpacity(0.5) : colorScheme.primary;
        border = BorderSide(color: isDisabled ? colorScheme.primary.withOpacity(0.2) : colorScheme.primary);
        break;
      case AppButtonVariant.danger:
        bgColor = isDisabled ? colorScheme.error.withOpacity(0.5) : colorScheme.error;
        fgColor = colorScheme.onError;
        if (!isDisabled && !_isPressed) {
          shadows = AppSpacing.shadowSm(bgColor);
        }
        break;
    }

    final child = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fgColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label, 
                style: AppTypography.button.copyWith(color: fgColor)
              ),
            ],
          );

    final buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: widget.fullWidth ? double.infinity : null,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 14.0, // Slightly custom for perfect vertical centering
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
        border: border != null ? Border.fromBorderSide(border) : null,
        boxShadow: shadows,
      ),
      child: Center(
        widthFactor: widget.fullWidth ? null : 1.0,
        child: child,
      ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: buttonContent,
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, danger }
