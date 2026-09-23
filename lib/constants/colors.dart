import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); 

  // Core Brand Colors
  static const Color emeraldBg = Color(0xFF064E3B);
  static const Color forestGreen = Color(0xFF008459);

  // Accent & Highlight Colors
  static const Color goldWarm = Color(0xFFE1A72B);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFE57F);

  // Neutral & Surface Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Financial Indicators
  static const Color positiveMint = Color(0xFF10B981);
  static const Color negativeRed = Color(0xFFEF4444);

  // Extended Palette (v1.1) — see BRAND.md section 5
  static const Color emeraldDeep = Color(0xFF022C22);
  static const Color emeraldGlow = Color(0xFF0B6B52);
  static const Color logoGreen = Color(0xFF00A860);
  static const Color goldDeep = Color(0xFFD09000);
  static const Color borderSlate = Color(0xFFE2E8F0);
  static const Color mintTint = Color(0xFFD1FAE5);
  static const Color redTint = Color(0xFFFEE2E2);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Brand Gradients (built only from the colors above)
  static const RadialGradient brandBackground = RadialGradient(
    center: Alignment(0, -0.16),
    radius: 1.1,
    colors: [emeraldGlow, emeraldBg, emeraldDeep],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient goldMetallic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, goldWarm, goldDeep],
  );
}