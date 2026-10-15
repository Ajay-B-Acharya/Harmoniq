import 'package:flutter/material.dart';

/// Dark Theme Neumorphic Palette Tokens
class AppDarkColors {
  const AppDarkColors._();

  static const Color background = Color(0xFF1E222B);
  static const Color backgroundSecondary = Color(0xFF181B22);
  static const Color backgroundSurface = Color(0xFF232833);
  static const Color surface = background;
  static const Color surfaceHigh = Color(0xFF262C37);
  static const Color lightShadow = Color(0xFF282F3C);
  static const Color darkShadow = Color(0xFF0F1217);
  static const Color darkShadowSubtle = Color(0xFF14171E);
  static const Color shadowStandard = Color(0x60000000);
  static const Color shadowFloating = Color(0x80000000);
  static const Color insetTrack = Color(0xFF15181F);
  static const Color insetHighlight = Color(0xFF262C38);
  static const Color insetShadow = Color(0xFF0B0D11);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = textTertiary;
  static const Color silver = Color(0xFF2A313E);
  static const Color borderStandard = Color(0x18FFFFFF);
  static const Color borderElevated = Color(0x28FFFFFF);
  static const Color divider = Color(0x20FFFFFF);
  static const Color dockSurface = Color(0xFF1E222B);
  static const Color dockActiveSurface = Color(0xFF282F3C);
  static const Color dockInactive = Color(0xFF64748B);
  static const Color playControlSurface = background;
  static const Color playControlForeground = textPrimary;
}

/// Neumorphism & Soft 3D UI Color Palette
///
/// Monochromatic soft surfaces, dual outer shadows for extruded plastic-like
/// elevation, tactile indentations for recessed tracks and active states,
/// with signature vibrant Coral (`#FF6444`) accents and rainbow 3D spectrum.
class AppColors {
  const AppColors._();

  // Neumorphic canvas and surfaces (identical monochromatic tone for plastic extrusion)
  static const Color background = Color(0xFFE8ECF2);
  static const Color backgroundSecondary = Color(0xFFE2E7ED);
  static const Color surface = Color(0xFFE8ECF2);
  static const Color surfaceHigh = Color(0xFFE8ECF2);
  static const Color backgroundSurface = Color(0xFFE8ECF2);

  // Dual shadows for extruded 3D surfaces
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color darkShadow = Color(0xFFB8C5D6);
  static const Color darkShadowSubtle = Color(0xFFBAC5D5);
  static const Color shadowStandard = Color(0x50BAC5D5);
  static const Color shadowFloating = Color(0x60A6B4C9);
  static const Color glassShadow = shadowStandard;

  // Inset / Concave track & indentation colors
  static const Color insetTrack = Color(0xFFDFE5ED);
  static const Color insetHighlight = Color(0xFFFFFFFF);
  static const Color insetShadow = Color(0xFFB0BDCF);

  // Deep navy & slate tones for contrast
  static const Color midnightNavy = Color(0xFF1E293B);
  static const Color deepBlue = Color(0xFF2C3E50);

  // Signature Coral / Orange Accent
  static const Color coral = Color(0xFFFF6444);
  static const Color coralLight = Color(0xFFFF856A);
  static const Color coralDark = Color(0xFFE04A2B);
  static const Color primaryCyan = coral;
  static const Color accent = coral;
  static const Color accentLight = coralLight;
  static const Color accentDark = coralDark;
  static const Color cyan = coral;
  static const Color lightCyan = coralLight;
  static const Color softCyan = coralLight;
  static const Color electricBlue = Color(0xFF4A7BD0);
  static const Color blue = Color(0xFF4A7BD0);
  static const Color silver = Color(0xFFE8ECF2);
  static const Color heartColor = Color(0xFFFF4866);
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);

  // Rainbow 3D Spectrum
  static const Color chartCoral = Color(0xFFFF5252);
  static const Color chartOrange = Color(0xFFFF7A30);
  static const Color chartAmber = Color(0xFFFFD13B);
  static const Color chartGreen = Color(0xFF6DD400);
  static const Color chartTeal = Color(0xFF28C76F);
  static const Color chartCyan = Color(0xFF00CFE8);

  static const List<Color> rainbowSpectrum = [
    chartCoral,
    chartOrange,
    chartAmber,
    chartGreen,
    chartTeal,
    chartCyan,
    chartCoral,
  ];

  // Soft glass / surface compat aliases for Neumorphic cards
  static const Color glassPrimary = Color(0xFFE8ECF2);
  static const Color glassSecondary = Color(0xFFE8ECF2);
  static const Color glassElevated = Color(0xFFE8ECF2);
  static const Color glassSelected = Color(0xFFDFE5ED);
  static const Color glassBlueTint = Color(0xFFE4EBF4);
  static const Color glassCyanTint = Color(0xFFE4EBF4);
  static const Color floatingGlass = Color(0xFFE8ECF2);
  static const Color sheetSurface = Color(0xFFE8ECF2);
  static const Color glassBackground = glassPrimary;

  // Overlays
  static const Color blurCyanOverlay = Color(0x10FF6444);
  static const Color blurBlueOverlay = Color(0x084A7BD0);
  static const Color blurNeutralOverlay = Color(0x10FFFFFF);
  static const Color blurSelectedOverlay = Color(0x20FF6444);

  // Subtle borders & specular highlights
  static const Color borderStandard = Color(0x20FFFFFF);
  static const Color borderElevated = Color(0x35FFFFFF);
  static const Color surfaceBorder = borderStandard;
  static const Color divider = Color(0x15000000);
  static const Color borderActiveCyan = Color(0x80FF6444);
  static const Color specularHighlight = Color(0x60FFFFFF);
  static const Color glassBorder = borderStandard;
  static const Color glassBorderGlow = borderActiveCyan;
  static const Color glassBorderCyan = borderActiveCyan;

  static const Color shadowActiveCyan = Color(0x30FF6444);
  static const Color shadowCyanAccent = Color(0x25FF6444);

  // High-legibility typography
  static const Color textPrimary = Color(0xFF202A36);
  static const Color textSecondary = Color(0xFF7A8B9E);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textMuted = textTertiary;

  // Floating dock & bottom navigation
  static const Color dockSurface = Color(0xFFE8ECF2);
  static const Color dockBorder = Color(0x30FFFFFF);
  static const Color dockActiveSurface = Color(0xFFDFE5ED);
  static const Color dockActiveBorder = Color(0x40FFFFFF);
  static const Color dockActiveGlow = Color(0x25FF6444);
  static const Color dockInactive = Color(0xFF8B9CB2);

  // Playback control surfaces
  static const Color playControlSurface = Color(0xFFE8ECF2);
  static const Color playControlForeground = Color(0xFF202A36);
  static const Color metallicAccent = Color(0xFFB8C5D6);

  // Atmosphere gradients
  static const Color nebulaBlue = Color(0x104A7BD0);
  static const Color nebulaCyan = Color(0x10FF6444);
  static const Color nebulaCoolBlue = Color(0x12BAC5D5);

  static const List<Color> gradientBlueCosmic = [
    Color(0xFFE2E8F0),
    Color(0xFFCBD5E1),
  ];
  static const List<Color> gradientElectricBlue = [
    Color(0xFFE0E7FF),
    Color(0xFFC7D2FE),
  ];
  static const List<Color> gradientCyanDepth = [
    Color(0xFFFFEDD5),
    Color(0xFFFED7AA),
  ];
  static const List<Color> gradientBlueAura = [
    Color(0xFFE0F2FE),
    Color(0xFFBAE6FD),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFFF1F5F9),
    Color(0xFFE2E8F0),
  ];
  static const List<Color> gradientStarlightTeal = [
    Color(0xFFCCFBF1),
    Color(0xFF99F6E4),
  ];
  static const List<Color> gradientOceanBlue = [
    Color(0xFFDBEAFE),
    Color(0xFFBFDBFE),
  ];
  static const List<Color> gradientDarkOrbit = [
    Color(0xFFE2E8F0),
    Color(0xFFCBD5E1),
  ];
  static const List<Color> gradientHero = [
    Color(0xFFE8ECF2),
    Color(0xFFDFE5ED),
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

  // Context-aware theme color helpers
  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.background
          : background;

  static Color lightShadowOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.lightShadow
          : lightShadow;

  static Color darkShadowOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.darkShadow
          : darkShadow;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.textPrimary
          : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppDarkColors.textSecondary
          : textSecondary;
}
