import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED COIN STACK — Beautiful 3D-like coins for the dashboard
// ══════════════════════════════════════════════════════════════════════════════

class AnimatedCoinStack extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;

  const AnimatedCoinStack({
    super.key,
    this.width = 100,
    this.height = 100,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedCoinStack> createState() => _AnimatedCoinStackState();
}

class _AnimatedCoinStackState extends State<AnimatedCoinStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _stackAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _stackAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    // Add a slight delay before animating in
    Future.delayed(const Duration(milliseconds: 300), () {
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _stackAnim,
        builder: (context, child) {
          return CustomPaint(
            painter: _CoinStackPainter(progress: _stackAnim.value),
          );
        },
      ),
    );
  }
}

class _CoinStackPainter extends CustomPainter {
  final double progress;

  _CoinStackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final coinWidth = size.width * 0.8;
    final coinHeight = size.height * 0.25;
    final coinSpacing = size.height * 0.12;

    final basePaint = Paint()
      ..color = const Color(0xFFF1C40F)
      ..style = PaintingStyle.fill;
    
    final highlightPaint = Paint()
      ..color = const Color(0xFFF39C12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Number of coins
    const numCoins = 4;

    for (int i = 0; i < numCoins; i++) {
      // Calculate progress for this specific coin (staggered)
      final coinProgressStart = i * 0.15;
      var coinProgress = (progress - coinProgressStart) / (1.0 - coinProgressStart);
      coinProgress = coinProgress.clamp(0.0, 1.0);

      if (coinProgress <= 0) continue;

      // Drop down animation
      final dropOffset = (1.0 - coinProgress) * (size.height * 0.5);
      
      final yPos = size.height - (i * coinSpacing) - (coinHeight / 2) - dropOffset;

      final rect = Rect.fromCenter(
        center: Offset(centerX, yPos),
        width: coinWidth,
        height: coinHeight,
      );

      // Draw shadow
      canvas.drawOval(rect.translate(0, 4), shadowPaint);
      
      // Draw cylinder body
      final bodyRect = Rect.fromLTRB(
        rect.left,
        rect.top + (coinHeight / 2),
        rect.right,
        rect.bottom + (coinSpacing * 0.5),
      );
      
      final bodyPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFD35400), Color(0xFFF39C12), Color(0xFFD35400)],
        ).createShader(bodyRect);
      
      canvas.drawRect(bodyRect, bodyPaint);

      // Draw top face
      canvas.drawOval(rect, basePaint);
      canvas.drawOval(rect, highlightPaint);
      
      // Draw subtle inner highlight
      final innerRect = rect.deflate(4);
      final innerPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawOval(innerRect, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_CoinStackPainter oldDelegate) => oldDelegate.progress != progress;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED CHECKMARK — Success state animation
// ══════════════════════════════════════════════════════════════════════════════

class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const AnimatedCheckmark({
    super.key,
    this.size = 100,
    this.color = const Color(0xFF00B894),
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(const Duration(milliseconds: 200), () {
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final circlePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw background circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, circlePaint);

    if (progress == 0) return;

    // Draw checkmark
    final path = Path();
    
    // Checkmark points
    final start = Offset(size.width * 0.25, size.height * 0.5);
    final mid = Offset(size.width * 0.45, size.height * 0.7);
    final end = Offset(size.width * 0.75, size.height * 0.35);

    // Line 1 (short side)
    final p1Progress = (progress * 2).clamp(0.0, 1.0);
    if (p1Progress > 0) {
      final currentMid = Offset.lerp(start, mid, p1Progress)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentMid.dx, currentMid.dy);
    }

    // Line 2 (long side)
    final p2Progress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
    if (p2Progress > 0) {
      final currentEnd = Offset.lerp(mid, end, p2Progress)!;
      path.moveTo(mid.dx, mid.dy);
      path.lineTo(currentEnd.dx, currentEnd.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) => oldDelegate.progress != progress;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED ORBITING ORBS — For empty/loading states
// ══════════════════════════════════════════════════════════════════════════════

class AnimatedOrbitingOrbs extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;

  const AnimatedOrbitingOrbs({
    super.key,
    this.size = 150,
    this.primaryColor = const Color(0xFF00B894),
    this.secondaryColor = const Color(0xFF00CECE),
  });

  @override
  State<AnimatedOrbitingOrbs> createState() => _AnimatedOrbitingOrbsState();
}

class _AnimatedOrbitingOrbsState extends State<AnimatedOrbitingOrbs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _OrbitPainter(
              progress: _controller.value,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _OrbitPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // Draw central glowing orb
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor,
          primaryColor.withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.2, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.4));
      
    canvas.drawCircle(center, maxRadius * 0.4, centerPaint);

    // Draw orbits
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawCircle(center, maxRadius * 0.6, orbitPaint);
    canvas.drawCircle(center, maxRadius * 0.8, orbitPaint);

    // Draw orbiting dots
    _drawOrb(canvas, center, maxRadius * 0.6, progress * pi * 2, primaryColor, 8);
    _drawOrb(canvas, center, maxRadius * 0.8, -progress * pi * 2 * 1.5, secondaryColor, 6);
  }
  
  void _drawOrb(Canvas canvas, Offset center, double radius, double angle, Color color, double size) {
    final x = center.dx + cos(angle) * radius;
    final y = center.dy + sin(angle) * radius;
    
    final orbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
    canvas.drawCircle(Offset(x, y), size, orbPaint);
    
    // Solid core
    canvas.drawCircle(Offset(x, y), size * 0.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.progress != progress;
}
