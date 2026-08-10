import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Emerald Green)
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  
  static const Color secondaryLight = Color(0xFF047857); // Emerald 700
  static const Color secondaryDark = Color(0xFF10B981); // Emerald 500
  
  // Primary Variants
  static const Color primaryHoverLight = Color(0xFF059669); // Emerald 600
  static const Color primaryHoverDark = Color(0xFF34D399); // Emerald 400
  static const Color primaryMutedLight = Color(0x1910B981); // 10% opacity
  static const Color primaryMutedDark = Color(0x1910B981); // 10% opacity
  
  // Semantic Colors - Light Mode
  static const Color successLight = Color(0xFF16A34A); // Green 600
  static const Color warningLight = Color(0xFFEA580C); // Orange 600
  static const Color dangerLight = Color(0xFFDC2626); // Red 600
  static const Color infoLight = Color(0xFF0EA5E9); // Sky 600
  
  // Semantic Colors - Dark Mode
  static const Color successDark = Color(0xFF22C55E); // Green 500
  static const Color warningDark = Color(0xFFF59E0B); // Amber 500 (updated)
  static const Color dangerDark = Color(0xFFEF4444); // Red 500
  static const Color infoDark = Color(0xFF0EA5E9); // Sky 500
  
  // Neutral Colors - Light Mode
  static const Color backgroundLight = Color(0xFFFAFAFA); // Gray 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF8FAFC); // Slate 50
  
  static const Color textPrimaryLight = Color(0xFF1F2937); // Gray 800
  static const Color textSecondaryLight = Color(0xFF6B7280); // Gray 500
  static const Color textTertiaryLight = Color(0xFF9CA3AF); // Gray 400
  
  static const Color borderLight = Color(0xFFE5E7EB); // Gray 200
  static const Color dividerLight = Color(0xFFF3F4F6); // Gray 100
  
  // Neutral Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceElevatedDark = Color(0xFF263548); // Slate 700.5
  
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiaryDark = Color(0xFF64748B); // Slate 500
  
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color dividerDark = Color(0xFF1E293B); // Slate 800
  
  // Sidebar / Navigation Rail
  static const Color sidebarLight = Color(0xFFF1F5F9); // Slate 100
  static const Color sidebarDark = Color(0xFF0B1120); // Darker than background
  
  // Focus Ring
  static const Color focusRingLight = Color(0x6610B981); // 40% primary
  static const Color focusRingDark = Color(0x6610B981); // 40% primary
  
  // Glassmorphism overlay
  static const Color glassLight = Color(0xD9FFFFFF); // 85% white
  static const Color glassDark = Color(0xD91E293B); // 85% slate 800
  
  // Overlay
  static const Color overlayLight = Color(0x0F000000);
  static const Color overlayDark = Color(0x1FFFFFFF);
  
  // Trend colors (explicit)
  static const Color trendUpLight = Color(0xFF16A34A);
  static const Color trendUpDark = Color(0xFF22C55E);
  static const Color trendDownLight = Color(0xFFDC2626);
  static const Color trendDownDark = Color(0xFFEF4444);
}
