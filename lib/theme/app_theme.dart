import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSlate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.6),
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
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerColor: AppColors.borderSlate,
    );
  }
}