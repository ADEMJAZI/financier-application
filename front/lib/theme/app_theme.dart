import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTypography.fontFamily,

    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      surface: AppColors.surfaceLight,
      error: AppColors.dangerLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    scaffoldBackgroundColor: AppColors.backgroundLight,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.textPrimaryLight),
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusMd)),
        side: BorderSide(color: AppColors.borderLight.withOpacity(0.5), width: 1),
      ),
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceElevatedLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusLg)),
      ),
      elevation: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevatedLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
        ),
        textStyle: AppTypography.button,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        textStyle: AppTypography.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.borderLight),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
        ),
        textStyle: AppTypography.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.borderLight.withOpacity(0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.borderLight.withOpacity(0.6)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.dangerLight),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiaryLight,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusMd)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textTertiaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.dividerLight,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(color: AppColors.borderLight.withOpacity(0.6)),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusFull)),
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════
  //  DARK THEME — FinTunis Premium Deep Navy
  // ══════════════════════════════════════════════════════════════
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTypography.fontFamily,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      surface: AppColors.surfaceDark,
      error: AppColors.dangerDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    scaffoldBackgroundColor: AppColors.backgroundDark,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.textPrimaryDark),
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusMd)),
        side: BorderSide(color: AppColors.borderDark.withOpacity(0.5), width: 1),
      ),
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusLg)),
      ),
      elevation: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
        ),
        textStyle: AppTypography.button,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        textStyle: AppTypography.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        side: const BorderSide(color: AppColors.borderDark),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
        ),
        textStyle: AppTypography.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundDark,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.borderDark.withOpacity(0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.borderDark.withOpacity(0.6)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
        borderSide: BorderSide(color: AppColors.dangerDark),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiaryDark,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusMd)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.textTertiaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceDark,
      side: BorderSide(color: AppColors.borderDark.withOpacity(0.6)),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusFull)),
      ),
    ),
  );
}
