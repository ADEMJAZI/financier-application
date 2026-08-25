import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

/// A premium, customizable card component designed for the SaaS aesthetic.
/// Automatically handles RTL layouts and provides subtle, premium shadows.
/// Supports optional gradient overlay and selected state glow.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool hasGlassmorphism;
  final double borderRadius;

  /// Optional gradient overlay for category-tinted cards
  final Gradient? gradientOverlay;

  /// When true, applies a glowing accent border for active/selected state
  final bool isSelected;

  /// Accent color used for selected glow (defaults to primary)
  final Color? selectedAccentColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.hasGlassmorphism = false,
    this.borderRadius = AppSpacing.radiusMd,
    this.gradientOverlay,
    this.isSelected = false,
    this.selectedAccentColor,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppSpacing.animFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _scaleController.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Base color
    Color bgColor = widget.backgroundColor ?? theme.cardColor;
    
    // Glassmorphism logic
    if (widget.hasGlassmorphism) {
      bgColor = bgColor.withOpacity(isDark ? 0.7 : 0.8);
    }

    // Border for dark mode to give it that crisp edge
    Border? border;
    if (widget.isSelected && widget.selectedAccentColor != null) {
      // Selected state: glowing accent border
      border = Border.all(
        color: widget.selectedAccentColor!.withOpacity(isDark ? 0.35 : 0.25),
        width: 1.5,
      );
    } else {
      border = isDark 
          ? Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08), width: 1)
          : Border.all(color: theme.colorScheme.onSurface.withOpacity(0.04), width: 1);
    }

    // Shadows
    List<BoxShadow>? shadows;
    if (widget.isSelected && widget.selectedAccentColor != null) {
      shadows = AppSpacing.shadowGlow(widget.selectedAccentColor!);
    } else if (!isDark) {
      shadows = _isHovered 
          ? AppSpacing.shadowLg(Colors.black)
          : AppSpacing.shadowSm(Colors.black);
    }

    final cardContent = AnimatedContainer(
      duration: AppSpacing.animMedium,
      curve: Curves.easeOut,
      margin: widget.margin ?? const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: widget.padding ?? const EdgeInsetsDirectional.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: widget.gradientOverlay == null ? bgColor : null,
        gradient: widget.gradientOverlay,
        borderRadius: BorderRadiusDirectional.all(Radius.circular(widget.borderRadius)),
        border: border,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: cardContent,
        ),
      ),
    );
  }
}
