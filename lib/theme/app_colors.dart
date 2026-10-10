import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0B1016);
  static const Color backgroundSecondary = Color(0xFF111820);
  static const Color backgroundSurface = Color(0xFF17212A);
  static const Color surfaceHigh = Color(0xFF202C36);
  static const Color surfaceBorder = Color(0x1FFFFFFF);

  static const Color primaryViolet = Color(0xFF86A9B3);
  static const Color secondaryPurple = Color(0xFF718D99);
  static const Color electricBlue = Color(0xFF6FA5B3);
  static const Color softCyan = Color(0xFF9BC7C1);

  static const Color accent = Color(0xFF8CBAB5);
  static const Color accentDark = Color(0xFF527E7B);
  static const Color accentLight = Color(0xFFB2D7D0);
  static const Color metallicAccent = Color(0xFFB8C4C8);
  static const Color heartColor = Color(0xFFE98B91);

  static const Color error = Color(0xFFE98B91);
  static const Color success = Color(0xFF83BBA5);

  static const Color glassBackground = Color(0x0FFFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassBorderGlow = Color(0x338CBAB5);
  static const Color glassBorderCyan = Color(0x338CBAB5);
  static const Color glassShadow = Color(0x66000000);

  static const Color textPrimary = Color(0xFFF1F3F2);
  static const Color textSecondary = Color(0xFFADB8BA);
  static const Color textMuted = Color(0xFF7F8C90);

  static const List<Color> gradientVioletCosmic = [
    Color(0xFF294148),
    Color(0xFF142027),
  ];
  static const List<Color> gradientElectricIndigo = [
    Color(0xFF283B46),
    Color(0xFF121D25),
  ];
  static const List<Color> gradientCyanDepth = [
    Color(0xFF24454A),
    Color(0xFF101F23),
  ];
  static const List<Color> gradientPurpleAura = [
    Color(0xFF3B3342),
    Color(0xFF1A1820),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFF26323A),
    Color(0xFF111820),
  ];
  static const List<Color> gradientStarlightTeal = [
    Color(0xFF264847),
    Color(0xFF12201F),
  ];
  static const List<Color> gradientNebulaRose = [
    Color(0xFF44333A),
    Color(0xFF1C171B),
  ];
  static const List<Color> gradientDarkOrbit = [
    Color(0xFF25313A),
    Color(0xFF10161D),
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
