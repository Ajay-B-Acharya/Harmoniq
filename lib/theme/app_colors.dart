import 'package:flutter/material.dart';

class AppColors {
  // Deep, modern, dark interface
  static const Color background = Color(0xFF0C0D10);
  static const Color backgroundSurface = Color(0xFF14161C);
  static const Color surfaceHigh = Color(0xFF1C1F27);
  static const Color surfaceBorder = Color(0xFF252933);

  // Warm, studio-grade sonic amber accent (distinctive, non-purple)
  static const Color accent = Color(0xFFFF9E3B);
  static const Color accentLight = Color(0xFFFFB866);
  static const Color heartColor = Color(0xFFEF4444);

  // Subtle flat / matte card surfaces without excessive glassmorphism
  static const Color glassBackground = Color(0xFF14161C);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.08);
  static final Color glassShadow = Colors.black.withValues(alpha: 0.25);

  // Crisp, accessible typography
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Subtle, restrained album artwork backdrops - strictly NO purple gradients
  static const List<Color> gradientSunset = [
    Color(0xFF5A3428),
    Color(0xFF281510),
  ];
  static const List<Color> gradientOcean = [
    Color(0xFF1E3A5F),
    Color(0xFF0F1E32),
  ];
  static const List<Color> gradientVapor = [
    Color(0xFF2B3240),
    Color(0xFF161A22),
  ];
  static const List<Color> gradientEmerald = [
    Color(0xFF1B4D3E),
    Color(0xFF0D2820),
  ];
  static const List<Color> gradientMidnight = [
    Color(0xFF243044),
    Color(0xFF121924),
  ];
  static const List<Color> gradientFiery = [
    Color(0xFF5A3E1B),
    Color(0xFF2C1D0C),
  ];
  static const List<Color> gradientAmethyst = [
    Color(0xFF4A3428),
    Color(0xFF241812),
  ];
  static const List<Color> gradientAura = [
    Color(0xFF343E48),
    Color(0xFF1A2026),
  ];

  static const List<List<Color>> allGradients = [
    gradientVapor,
    gradientOcean,
    gradientSunset,
    gradientEmerald,
    gradientMidnight,
    gradientFiery,
    gradientAmethyst,
    gradientAura,
  ];

  static List<Color> getGradientForId(int id) =>
      allGradients[id % allGradients.length];
}
