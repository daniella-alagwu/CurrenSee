import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emeraldBg,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emeraldBg,
      secondary: AppColors.goldWarm,
      surface: AppColors.white,
      error: AppColors.negativeRed,
      onPrimary: AppColors.white,
      onSecondary: AppColors.textDark,
      onSurface: AppColors.textDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.montserratTextTheme(
  ThemeData.light().textTheme,
).copyWith(
  displayLarge: GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  ),
  displayMedium: GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  ),
  displaySmall: GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  ),
  headlineLarge: GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  ),
  headlineMedium: GoogleFonts.montserrat(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  ),
  headlineSmall: GoogleFonts.montserrat(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
  titleLarge: GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
  titleMedium: GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
  titleSmall: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
  bodyLarge: GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  ),
  bodyMedium: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  ),
  bodySmall: GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  ),
  labelLarge: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
  labelMedium: GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
  labelSmall: GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  ),
),

      scaffoldBackgroundColor: AppColors.white,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldWarm,
          foregroundColor: AppColors.textDark,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderSlate,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.forestGreen,
            width: 1.6,
          ),
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.forestGreen,
        labelColor: AppColors.forestGreen,
        unselectedLabelColor: AppColors.textMuted,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forestGreen
              : AppColors.borderSlate,
        ),
        trackOutlineColor: WidgetStateProperty.all(
          Colors.transparent,
        ),
      ),

      dividerColor: AppColors.borderSlate,
    );
  }
}

