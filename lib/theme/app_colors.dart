import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF05070D);
  static const Color backgroundSecondary = Color(0xFF080D18);
  static const Color midnightNavy = Color(0xFF0B1220);
  static const Color deepBlue = Color(0xFF10213A);

  static const Color nebulaBlue = Color(0x212563EB);
  static const Color nebulaCyan = Color(0x1306B6D4);
  static const Color nebulaCoolBlue = Color(0x173B82F6);

  static const Color glassPrimary = Color(0x09FFFFFF);
  static const Color glassSecondary = Color(0x0BFFFFFF);
  static const Color glassElevated = Color(0x0EFFFFFF);
  static const Color glassSelected = Color(0x1A38D9F5);
  static const Color glassBlueTint = Color(0x0A4F8CFF);
  static const Color glassCyanTint = Color(0x0B38D9F5);
  static const Color floatingGlass = Color(0x78080D18);
  static const Color sheetSurface = Color(0xD9080D18);
  static const Color glassBackground = glassPrimary;
  static const Color backgroundSurface = glassSecondary;
  static const Color surfaceHigh = glassElevated;
  static const Color surfaceBorder = borderStandard;

  static const Color blurCyanOverlay = Color(0x0938D9F5);
  static const Color blurBlueOverlay = Color(0x064F8CFF);
  static const Color blurNeutralOverlay = Color(0x06FFFFFF);
  static const Color blurSelectedOverlay = Color(0x1938D9F5);

  static const Color borderStandard = Color(0x29FFFFFF);
  static const Color borderElevated = Color(0x33FFFFFF);
  static const Color divider = Color(0x17FFFFFF);
  static const Color borderActiveCyan = Color(0x7338D9F5);
  static const Color specularHighlight = Color(0x38FFFFFF);
  static const Color glassBorder = borderStandard;
  static const Color glassBorderGlow = borderActiveCyan;
  static const Color glassBorderCyan = borderActiveCyan;

  static const Color shadowStandard = Color(0x2E000000);
  static const Color shadowFloating = Color(0x47000000);
  static const Color shadowActiveCyan = Color(0x1F38D9F5);
  static const Color shadowCyanAccent = Color(0x1F06B6D4);
  static const Color glassShadow = shadowStandard;

  static const Color primaryCyan = Color(0xFF38D9F5);
  static const Color lightCyan = Color(0xFF8BE9F8);
  static const Color blue = Color(0xFF4F8CFF);
  static const Color silver = Color(0xFFDCE6F2);
  static const Color cyan = primaryCyan;
  static const Color heartColor = Color(0xFFFB7185);
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);
  static const Color accent = primaryCyan;
  static const Color accentLight = lightCyan;
  static const Color accentDark = blue;
  static const Color electricBlue = blue;
  static const Color softCyan = lightCyan;
  static const Color metallicAccent = silver;
  static const Color playControlSurface = silver;
  static const Color playControlForeground = midnightNavy;

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFA8B3C7);
  static const Color textTertiary = Color(0xFF78869B);
  static const Color textMuted = textTertiary;

  static const Color dockSurface = Color(0xB8080D18);
  static const Color dockBorder = Color(0x2EFFFFFF);
  static const Color dockActiveSurface = Color(0x1A38D9F5);
  static const Color dockActiveBorder = Color(0x7338D9F5);
  static const Color dockActiveGlow = Color(0x1F38D9F5);
  static const Color dockInactive = Color(0x99DCE6F2);

  static const List<Color> gradientBlueCosmic = [
    Color(0xFF12304E),
    Color(0xFF08111E),
  ];
  static const List<Color> gradientElectricBlue = [
    Color(0xFF183B72),
    Color(0xFF0A1425),
  ];
  static const List<Color> gradientCyanDepth = [
    Color(0xFF0D3F4C),
    Color(0xFF071A24),
  ];
  static const List<Color> gradientBlueAura = [
    Color(0xFF17365E),
    Color(0xFF091323),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFF1B2B40),
    Color(0xFF0C1420),
  ];
  static const List<Color> gradientStarlightTeal = [
    Color(0xFF113E42),
    Color(0xFF081D21),
  ];
  static const List<Color> gradientOceanBlue = [
    Color(0xFF16466E),
    Color(0xFF081724),
  ];
  static const List<Color> gradientDarkOrbit = [
    Color(0xFF1F2B3D),
    Color(0xFF0C101A),
  ];
  static const List<Color> gradientHero = [
    deepBlue,
    Color(0xFF0B1A2D),
    background,
  ];

  static const List<List<Color>> allGradients = [
    gradientBlueCosmic,
    gradientElectricBlue,
    gradientCyanDepth,
    gradientBlueAura,
    gradientMidnightSteel,
    gradientStarlightTeal,
    gradientOceanBlue,
    gradientDarkOrbit,
  ];

  static List<Color> getGradientForId(int id) =>
      allGradients[id % allGradients.length];
}
