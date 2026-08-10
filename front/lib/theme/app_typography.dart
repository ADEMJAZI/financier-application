import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // We don't define a single static fontFamily anymore. 
  // We apply GoogleFonts directly to the TextStyles or the ThemeData.
  static final String? fontFamily = GoogleFonts.cairo().fontFamily;
  
  // Inter for numbers and currency values (cleaner digit rendering)
  static final String? numberFontFamily = GoogleFonts.inter().fontFamily;
  
  // Font Weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  
  // Display
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: bold,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.4,
  );
  
  // Body
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
  
  // Labels & Captions
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
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.4,
  );
  
  // Button
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  // Currency / Financial values — uses Inter for crisp number rendering
  // Apply via: style.copyWith(fontFamily: AppTypography.numberFontFamily)
  static const TextStyle currencyLarge = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle currencyMedium = TextStyle(
    fontSize: 20,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.3,
  );
  
  static const TextStyle currencySmall = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.3,
  );
  
  // Trend indicator (small % text next to currency values)
  static const TextStyle trend = TextStyle(
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.3,
  );
}
