import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// A wrapper widget that scales down slightly when pressed,
/// providing tactile, bouncy feedback to the user.
class BouncyTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleDown;
  final Duration duration;

  const BouncyTapWidget({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleDown = 0.97,
    this.duration = AppSpacing.animFast,
  });

  @override
  State<BouncyTapWidget> createState() => _BouncyTapWidgetState();
}

class _BouncyTapWidgetState extends State<BouncyTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
