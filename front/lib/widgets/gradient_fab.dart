import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A vibrant gradient floating action button with glow shadow and
/// scale-bounce animation on tap.
/// Uses AlignmentDirectional for RTL-safe gradient direction.
class GradientFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final String? heroTag;
  final double size;

  const GradientFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.heroTag,
    this.size = 56,
  });

  @override
  State<GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<GradientFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        widget.onPressed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExtended = widget.label != null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          height: widget.size,
          width: isExtended ? null : widget.size,
          padding: isExtended
              ? const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.lg,
                )
              : null,
          decoration: BoxDecoration(
            gradient: AppColors.fabGradient,
            borderRadius: BorderRadiusDirectional.all(
              Radius.circular(isExtended ? AppSpacing.radiusMd : widget.size / 2),
            ),
            boxShadow: AppColors.fabGlow(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 24,
              ),
              if (isExtended) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
