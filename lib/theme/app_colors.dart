import 'package:flutter/material.dart';

class AppColors {
  // Spatial UI primary & secondary backgrounds
  static const Color background = Color(0xFF101522);
  static const Color backgroundSecondary = Color(0xFF171D30);
  static const Color backgroundSurface = Color(0xFF1A2138);
  static const Color surfaceHigh = Color(0xFF222B45);
  static const Color surfaceBorder = Color(0x29FFFFFF); // rgba(255, 255, 255, 0.16)

  // Spatial UI vibrant accents
  static const Color primaryViolet = Color(0xFF9B7BFF);
  static const Color secondaryPurple = Color(0xFFC084FC);
  static const Color electricBlue = Color(0xFF69B7FF);
  static const Color softCyan = Color(0xFF7CEBFF);

  static const Color accent = Color(0xFF9B7BFF);
  static const Color accentDark = Color(0xFF7551E9);
  static const Color accentLight = Color(0xFF7CEBFF);
  static const Color metallicAccent = Color(0xFFB6BCD2);
  static const Color heartColor = Color(0xFFFF6B81);

  // Status colors
  static const Color error = Color(0xFFFF6B81);
  static const Color success = Color(0xFF79E6C5);

  // Frosted glass tokens
  static const Color glassBackground = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color glassBorder = Color(0x29FFFFFF);     // rgba(255, 255, 255, 0.16)
  static const Color glassBorderGlow = Color(0x4D9B7BFF); // Soft violet glow border
  static const Color glassBorderCyan = Color(0x4D7CEBFF); // Soft cyan glow border
  static const Color glassShadow = Color(0x4D050914);

  // Crisp, accessible Spatial typography
  static const Color textPrimary = Color(0xFFF5F6FF);
  static const Color textSecondary = Color(0xFFB6BCD2);
  static const Color textMuted = Color(0xFF858DA8);

  // Atmospheric gradients for artwork and ambient highlights
  static const List<Color> gradientVioletCosmic = [
    Color(0xFF2D1B69),
    Color(0xFF130E29),
  ];
  static const List<Color> gradientElectricIndigo = [
    Color(0xFF1B2E6A),
    Color(0xFF0F1735),
  ];
  static const List<Color> gradientCyanDepth = [
    Color(0xFF163C52),
    Color(0xFF0D1D2B),
  ];
  static const List<Color> gradientPurpleAura = [
    Color(0xFF3B1E5C),
    Color(0xFF160B26),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFF222B45),
    Color(0xFF121727),
  ];
  static const List<Color> gradientStarlightTeal = [
    Color(0xFF19444B),
    Color(0xFF0E2226),
  ];
  static const List<Color> gradientNebulaRose = [
    Color(0xFF451E38),
    Color(0xFF1A0A16),
  ];
  static const List<Color> gradientDarkOrbit = [
    Color(0xFF252D42),
    Color(0xFF101420),
  ];

  static const List<List<Color>> allGradients = [
    gradientVioletCosmic,
    gradientElectricIndigo,
    gradientCyanDepth,
    gradientPurpleAura,
    gradientMidnightSteel,
    gradientStarlightTeal,
    gradientNebulaRose,
    gradientDarkOrbit,
  ];

  static List<Color> getGradientForId(int id) =>
      allGradients[id % allGradients.length];
}
