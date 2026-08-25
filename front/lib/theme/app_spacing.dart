import 'package:flutter/material.dart';

class AppSpacing {
  // ══════════════════════════════════════════════════════════════
  //  SPACING SCALE (4px base unit)
  // ══════════════════════════════════════════════════════════════
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ══════════════════════════════════════════════════════════════
  //  BORDER RADIUS — Smoother, larger premium curves
  // ══════════════════════════════════════════════════════════════
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 20.0;    // Cards, dialogs — larger & smoother
  static const double radiusLg = 28.0;    // Bottom sheets, modals
  static const double radiusXl = 36.0;    // Hero cards
  static const double radiusFull = 9999.0;

  // ══════════════════════════════════════════════════════════════
  //  RESPONSIVE BREAKPOINTS
  // ══════════════════════════════════════════════════════════════
  static const double breakpointCompact = 600.0;
  static const double breakpointMedium = 840.0;
  static const double breakpointExpanded = 1200.0;

  // Navigation dimensions
  static const double sidebarWidth = 80.0;
  static const double sidebarExpandedWidth = 260.0;
  static const double bottomNavHeight = 88.0;

  // Minimum touch target (WCAG / Material guidelines)
  static const double minTouchTarget = 48.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // ══════════════════════════════════════════════════════════════
  //  ANIMATION TIMING
  // ══════════════════════════════════════════════════════════════

  /// Fast animation — tap feedback, scale press
  static const Duration animFast = Duration(milliseconds: 120);

  /// Medium animation — container transitions, fade switches
  static const Duration animMedium = Duration(milliseconds: 280);

  /// Slow animation — entrance animations, stagger reveals
  static const Duration animSlow = Duration(milliseconds: 450);

  /// Delay between staggered list items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Snappy curve for entrance/exit animations
  static const Curve curveSnappy = Curves.easeOutCubic;

  /// Bouncy curve for scale-up springs
  static const Curve curveBouncy = Curves.elasticOut;

  /// Smooth deceleration curve
  static const Curve curveSmooth = Curves.easeOutQuart;

  // ══════════════════════════════════════════════════════════════
  //  PREMIUM SHADOWS
  // ══════════════════════════════════════════════════════════════

  static List<BoxShadow> shadowSm(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: color.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Glow shadow — used for accent-colored glowing elements
  static List<BoxShadow> shadowGlow(Color color, {double blur = 16, double spread = 0}) => [
    BoxShadow(
      color: color.withOpacity(0.30),
      blurRadius: blur,
      spreadRadius: spread,
    ),
  ];

  /// Elevated card shadow for floating elements
  static List<BoxShadow> shadowElevated(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: color.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
