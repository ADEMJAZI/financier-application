import 'package:flutter/material.dart';

class AppColors {
  // ══════════════════════════════════════════════════════════════
  //  PRIMARY PALETTE — Vibrant Emerald (FinTunis Brand)
  // ══════════════════════════════════════════════════════════════
  static const Color primaryLight = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF10B981);  // Emerald 500

  static const Color secondaryLight = Color(0xFFD97706); // Amber 600
  static const Color secondaryDark = Color(0xFFF59E0B);  // Amber 500

  // ══════════════════════════════════════════════════════════════
  //  SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════
  static const Color successLight = Color(0xFF10B981);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color infoLight = Color(0xFF3B82F6);

  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color dangerDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF60A5FA);

  // ══════════════════════════════════════════════════════════════
  //  NEUTRAL — LIGHT MODE (Crisp & Clean)
  // ══════════════════════════════════════════════════════════════
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // ══════════════════════════════════════════════════════════════
  //  NEUTRAL — DARK MODE (Deep Navy — FinTunis Premium)
  // ══════════════════════════════════════════════════════════════
  static const Color backgroundDark = Color(0xFF0F172A);           // Slate 900 — deep navy
  static const Color surfaceDark = Color(0xFF1E293B);              // Slate 800
  static const Color cardDark = Color(0xFF1E293B);                 // Slate 800
  static const Color surfaceElevatedDark = Color(0xFF334155);      // Slate 700

  static const Color textPrimaryDark = Color(0xFFF8FAFC);          // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8);        // Slate 400
  static const Color textTertiaryDark = Color(0xFF64748B);         // Slate 500

  static const Color borderDark = Color(0xFF334155);               // Slate 700
  static const Color dividerDark = Color(0xFF1E293B);              // Slate 800

  // Sidebar / Navigation Rail
  static const Color sidebarLight = Color(0xFFFFFFFF);
  static const Color sidebarDark = Color(0xFF0F172A);

  // Glassmorphism
  static const Color glassLight = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0xCC1E293B);

  // Overlay
  static const Color overlayLight = Color(0x1A000000);
  static const Color overlayDark = Color(0x4D000000);

  // Trend colors
  static const Color trendUpLight = Color(0xFF10B981);
  static const Color trendUpDark = Color(0xFF34D399);
  static const Color trendDownLight = Color(0xFFEF4444);
  static const Color trendDownDark = Color(0xFFF87171);

  // ══════════════════════════════════════════════════════════════
  //  GRADIENT & GLOW CONSTANTS
  // ══════════════════════════════════════════════════════════════

  /// Category gradient overlays for KPI / stat cards.
  static LinearGradient categoryGradient(String category, {bool isDark = true}) {
    final colors = _categoryGradientColors[category] ?? _categoryGradientColors['primary']!;
    final opacity = isDark ? 0.18 : 0.10;
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        colors[0].withOpacity(opacity),
        colors[1].withOpacity(opacity * 0.15),
      ],
    );
  }

  static const Map<String, List<Color>> _categoryGradientColors = {
    'revenue':  [Color(0xFF10B981), Color(0xFF059669)],
    'products': [Color(0xFF14B8A6), Color(0xFF0D9488)],
    'restock':  [Color(0xFFF59E0B), Color(0xFFD97706)],
    'debts':    [Color(0xFFEF4444), Color(0xFFDC2626)],
    'cashflow': [Color(0xFF3B82F6), Color(0xFF2563EB)],
    'primary':  [Color(0xFF10B981), Color(0xFF059669)],
    'expense':  [Color(0xFFF97316), Color(0xFFEA580C)],
    'salary':   [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'rent':     [Color(0xFF6366F1), Color(0xFF4F46E5)],
    'utility':  [Color(0xFF06B6D4), Color(0xFF0891B2)],
  };

  /// Vibrant emerald gradient for FABs / primary action buttons
  static const LinearGradient fabGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Color(0xFF10B981), // Emerald 500
      Color(0xFF059669), // Emerald 600
    ],
  );

  /// Glow shadow for FAB — prominent outer glow
  static List<BoxShadow> fabGlow({Color? color}) => [
    BoxShadow(
      color: (color ?? const Color(0xFF10B981)).withOpacity(0.45),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: (color ?? const Color(0xFF10B981)).withOpacity(0.25),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  /// Avatar ring gradient
  static const SweepGradient avatarRingGradient = SweepGradient(
    colors: [
      Color(0xFF10B981),
      Color(0xFF14B8A6),
      Color(0xFF34D399),
      Color(0xFF10B981),
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  /// Selected / active state glow decoration for chips, cards, etc.
  static BoxDecoration selectedCardGlow(Color accentColor, {bool isDark = true}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          accentColor.withOpacity(isDark ? 0.14 : 0.08),
          accentColor.withOpacity(isDark ? 0.04 : 0.02),
        ],
      ),
      border: Border.all(
        color: accentColor.withOpacity(isDark ? 0.40 : 0.25),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(isDark ? 0.20 : 0.08),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Gradient fill beneath chart curves
  static LinearGradient chartGradientFill({Color? color, bool isDark = true}) {
    final c = color ?? const Color(0xFF10B981);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        c.withOpacity(isDark ? 0.30 : 0.20),
        c.withOpacity(0.0),
      ],
    );
  }

  /// Icon container gradient
  static LinearGradient iconContainerGradient(Color color, {bool isDark = true}) {
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        color.withOpacity(isDark ? 0.22 : 0.15),
        color.withOpacity(isDark ? 0.08 : 0.05),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  DECORATIVE GLOWING ORB — background decoration
  // ══════════════════════════════════════════════════════════════

  /// Creates a soft radial gradient "orb" decoration for background ambiance.
  static BoxDecoration glowingOrb(Color color, {double opacity = 0.12}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  /// Hero card decoration with subtle glow border
  static BoxDecoration heroCardDecoration({bool isDark = true, Color? glowColor}) {
    final glow = glowColor ?? const Color(0xFF10B981);
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: glow.withOpacity(isDark ? 0.25 : 0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glow.withOpacity(isDark ? 0.15 : 0.08),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Glass card decoration (frosted glass effect)
  static BoxDecoration glassCardDecoration({bool isDark = true}) {
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF1E293B).withOpacity(0.7)
          : Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        width: 1,
      ),
    );
  }
}
