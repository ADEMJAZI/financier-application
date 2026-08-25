import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Hanken Grotesk — clean, modern sans-serif with strong weight contrast
  // for a distinctive fintech personality.
  static final String? fontFamily = GoogleFonts.hankenGrotesk().fontFamily;

  // Inter — crisp tabular digits for currency values and numbers.
  static final String? numberFontFamily = GoogleFonts.inter().fontFamily;

  // Font Weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ══════════════════════════════════════════════════════════════
  //  DISPLAY — Oversized hero numbers
  // ══════════════════════════════════════════════════════════════
  static const TextStyle display = TextStyle(
    fontSize: 40,
    fontWeight: extraBold,
    height: 1.1,
    letterSpacing: -1.0,
  );

  // ══════════════════════════════════════════════════════════════
  //  HEADINGS
  // ══════════════════════════════════════════════════════════════
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: -0.4,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.3,
  );

  // ══════════════════════════════════════════════════════════════
  //  BODY
  // ══════════════════════════════════════════════════════════════
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.5,
  );

  // ══════════════════════════════════════════════════════════════
  //  LABELS & CAPTIONS
  // ══════════════════════════════════════════════════════════════
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: light,
    height: 1.4,
  );

  // ══════════════════════════════════════════════════════════════
  //  BUTTON
  // ══════════════════════════════════════════════════════════════
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: 0.3,
  );

  // ══════════════════════════════════════════════════════════════
  //  CURRENCY — Inter for crisp number rendering
  // ══════════════════════════════════════════════════════════════
  static const TextStyle currencyHero = TextStyle(
    fontSize: 42,
    fontWeight: extraBold,
    height: 1.0,
    letterSpacing: -1.5,
  );

  static const TextStyle currencyLarge = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.1,
    letterSpacing: -0.8,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontSize: 24,
    fontWeight: bold,
    height: 1.15,
    letterSpacing: -0.4,
  );

  static const TextStyle currencySmall = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // Trend indicator (small % text next to currency values)
  static const TextStyle trend = TextStyle(
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.2,
  );
}
