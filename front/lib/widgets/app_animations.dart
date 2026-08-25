import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ══════════════════════════════════════════════════════════════════════════════
//  SLIDE-IN WIDGET — Animate from any direction with stagger delay
// ══════════════════════════════════════════════════════════════════════════════

enum SlideDirection { left, right, top, bottom }

class SlideInWidget extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  const SlideInWidget({
    super.key,
    required this.child,
    this.direction = SlideDirection.bottom,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 40.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Offset begin;
    switch (widget.direction) {
      case SlideDirection.left:
        begin = Offset(-widget.offset, 0);
      case SlideDirection.right:
        begin = Offset(widget.offset, 0);
      case SlideDirection.top:
        begin = Offset(0, -widget.offset);
      case SlideDirection.bottom:
        begin = Offset(0, widget.offset);
    }
    _slideAnim = Tween<Offset>(begin: begin, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(offset: _slideAnim.value, child: child),
      ),
      child: widget.child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SCALE-IN WIDGET — Bouncy scale entrance
// ══════════════════════════════════════════════════════════════════════════════

class ScaleInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const ScaleInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.elasticOut,
  });

  @override
  State<ScaleInWidget> createState() => _ScaleInWidgetState();
}

class _ScaleInWidgetState extends State<ScaleInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.scale(scale: _scaleAnim.value, child: child),
      ),
      child: widget.child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHIMMER GLOW — Continuous shimmer sweep for premium elements
// ══════════════════════════════════════════════════════════════════════════════

class ShimmerGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final Duration duration;

  const ShimmerGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF00B894),
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ShimmerGlow> createState() => _ShimmerGlowState();
}

class _ShimmerGlowState extends State<ShimmerGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 0.5, 0),
              colors: [
                Colors.white,
                widget.glowColor.withOpacity(0.3),
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PULSE WIDGET — Gentle breathing pulse for icons / badges
// ══════════════════════════════════════════════════════════════════════════════

class PulseWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulseWidget({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: widget.minScale, end: widget.maxScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: widget.child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FLOATING WIDGET — Gentle up/down floating motion
// ══════════════════════════════════════════════════════════════════════════════

class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;

  const FloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 8.0,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -widget.amplitude, end: widget.amplitude)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _floatAnim.value), child: child),
      child: widget.child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ROTATE-IN WIDGET — Spin entrance for icons
// ══════════════════════════════════════════════════════════════════════════════

class RotateInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double turns;

  const RotateInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.turns = 1.0,
  });

  @override
  State<RotateInWidget> createState() => _RotateInWidgetState();
}

class _RotateInWidgetState extends State<RotateInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _rotateAnim = Tween<double>(begin: -widget.turns, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: RotationTransition(turns: _rotateAnim, child: child),
      ),
      child: widget.child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STAGGERED LIST BUILDER — Automatic staggered entrance for list items
// ══════════════════════════════════════════════════════════════════════════════

class StaggeredListBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Duration staggerDelay;
  final Duration itemDuration;
  final SlideDirection direction;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const StaggeredListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.itemDuration = const Duration(milliseconds: 450),
    this.direction = SlideDirection.bottom,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemBuilder: (context, index) {
        return SlideInWidget(
          direction: direction,
          delay: staggerDelay * index,
          duration: itemDuration,
          offset: 30,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED GRADIENT BORDER — Rotating gradient border for premium cards
// ══════════════════════════════════════════════════════════════════════════════

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 20.0,
    this.colors = const [
      Color(0xFF00B894),
      Color(0xFF00CECE),
      Color(0xFF6C35DE),
      Color(0xFF00B894),
    ],
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            progress: _controller.value,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            colors: widget.colors,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final double borderRadius;
  final List<Color> colors;

  _GradientBorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.borderRadius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 2,
        colors: colors,
        transform: GradientRotation(progress * pi * 2),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ══════════════════════════════════════════════════════════════════════════════
//  TYPEWRITER TEXT — Text appears letter by letter
// ══════════════════════════════════════════════════════════════════════════════

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final Duration delay;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 40),
    this.delay = Duration.zero,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charAnim;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.charDuration * widget.text.length;
    _controller = AnimationController(vsync: this, duration: totalDuration);
    _charAnim = IntTween(begin: 0, end: widget.text.length)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charAnim,
      builder: (context, _) {
        final visibleText = widget.text.substring(0, _charAnim.value);
        return Text(visibleText, style: widget.style);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PARTICLE BACKGROUND — Ambient floating dots for premium backgrounds
// ══════════════════════════════════════════════════════════════════════════════

class ParticleBackground extends StatefulWidget {
  final int particleCount;
  final Color color;
  final double maxRadius;

  const ParticleBackground({
    super.key,
    this.particleCount = 30,
    this.color = const Color(0xFF00B894),
    this.maxRadius = 3.0,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _particles = List.generate(widget.particleCount, (_) => _generateParticle());
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      radius: _random.nextDouble() * widget.maxRadius + 0.5,
      speedX: (_random.nextDouble() - 0.5) * 0.02,
      speedY: (_random.nextDouble() - 0.5) * 0.015,
      opacity: _random.nextDouble() * 0.4 + 0.1,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, radius, speedX, speedY, opacity, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Animate position with wrapping
      final t = progress * 10; // scale by duration
      final px = ((p.x + p.speedX * t + sin(t * 2 + p.phase) * 0.01) % 1.0) *
          size.width;
      final py = ((p.y + p.speedY * t + cos(t * 3 + p.phase) * 0.008) % 1.0) *
          size.height;

      // Pulsing opacity
      final pulsingOpacity =
          p.opacity * (0.6 + 0.4 * sin(progress * pi * 2 + p.phase));

      final paint = Paint()
        ..color = color.withOpacity(pulsingOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED PAGE ROUTE — Fade + slide transition
// ══════════════════════════════════════════════════════════════════════════════

class AnimatedPageTransition extends CustomTransitionPage<void> {


  AnimatedPageTransition({required super.child, super.key})
      : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );
            final slideAnim = Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

