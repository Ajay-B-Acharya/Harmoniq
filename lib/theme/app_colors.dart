import 'package:flutter/material.dart';

class AppColors {
  // Deep, modern, dark interface
  static const Color background = Color(0xFF080808);
  static const Color backgroundSecondary = Color(0xFF0D0D0D);
  static const Color backgroundSurface = Color(0xFF151515);
  static const Color surfaceHigh = Color(0xFF1C1C1C);
  static const Color surfaceBorder = Color(0xFF282828);

  // Red and metallic accents
  static const Color accent = Color(0xFFE50914);
  static const Color accentDark = Color(0xFF8F0B12);
  static const Color accentLight = Color(0xFFE50914);
  static const Color metallicAccent = Color(0xFFC8C8C8);
  static const Color heartColor = Color(0xFFE50914);

  // Subtle flat / matte card surfaces without excessive glassmorphism
  static const Color glassBackground = Color(0xFF151515);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.07);
  static final Color glassShadow = Colors.black.withValues(alpha: 0.35);

  // Crisp, accessible typography
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF666666);

  // Subtle, restrained album artwork backdrops - strictly NO purple or neon gradients
  static const List<Color> gradientDarkRed = [
    Color(0xFF3A0D11),
    Color(0xFF140708),
  ];
  static const List<Color> gradientCrimson = [
    Color(0xFF4A1015),
    Color(0xFF1C0A0C),
  ];
  static const List<Color> gradientCharcoal = [
    Color(0xFF2B2B2B),
    Color(0xFF141414),
  ];
  static const List<Color> gradientSilverSlate = [
    Color(0xFF33383E),
    Color(0xFF181B1E),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFF1F252E),
    Color(0xFF101419),
  ];
  static const List<Color> gradientDeepAsh = [
    Color(0xFF262626),
    Color(0xFF121212),
  ];
  static const List<Color> gradientOnyx = [
    Color(0xFF301E22),
    Color(0xFF180F11),
  ];
  static const List<Color> gradientGraphite = [
    Color(0xFF24272C),
    Color(0xFF121417),
  ];

  static const List<List<Color>> allGradients = [
    gradientDarkRed,
    gradientCharcoal,
    gradientCrimson,
    gradientSilverSlate,
    gradientMidnightSteel,
    gradientDeepAsh,
    gradientOnyx,
    gradientGraphite,
  ];

  static List<Color> getGradientForId(int id) =>
      allGradients[id % allGradients.length];
}
