import 'package:flutter/material.dart';

/// Dark Theme Neumorphic Palette Tokens (Pure Pitch Black AMOLED Dark)
class AppDarkColors {
  const AppDarkColors._();

  static const Color background = Color(0xFF000000);
  static const Color backgroundSecondary = Color(0xFF050505);
  static const Color backgroundSurface = Color(0xFF0A0A0A);
  static const Color surface = background;
  static const Color surfaceHigh = Color(0xFF101010);
  static const Color lightShadow = Color(0xFF1A1A1A);
  static const Color darkShadow = Color(0xFF000000);
  static const Color darkShadowSubtle = Color(0xFF000000);
  static const Color shadowStandard = Color(0x90000000);
  static const Color shadowFloating = Color(0xD0000000);
  static const Color insetTrack = Color(0xFF050505);
  static const Color insetHighlight = Color(0xFF141414);
  static const Color insetShadow = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);
  static const Color textMuted = textTertiary;
  static const Color silver = Color(0xFF101010);
  static const Color borderStandard = Color(0x1FFFFFFF);
  static const Color borderElevated = Color(0x33FFFFFF);
  static const Color divider = Color(0x18FFFFFF);
  static const Color dockSurface = Color(0xFF050505);
  static const Color dockBorder = Color(0x22FFFFFF);
  static const Color dockActiveSurface = Color(0xFF141414);
  static const Color dockInactive = Color(0xFF71717A);
  static const Color cardSurface = Color(0xFF0A0A0A);
  static const Color cardBorder = Color(0x1FFFFFFF);
  static const Color playControlSurface = background;
  static const Color playControlForeground = textPrimary;
}

/// Neumorphism & Soft 3D UI Color Palette (Rich Warm Cream Light Canvas)
///
/// Monochromatic warm cream surfaces, dual outer shadows for extruded plastic-like
/// elevation, tactile indentations for recessed tracks and active states,
/// with signature gentle Coral (`#F06A4F`) accents.
class AppColors {
  const AppColors._();

  // Neumorphic canvas and surfaces (identical warm creamy tone)
  static const Color background = Color(0xFFFBF6EC);
  static const Color backgroundSecondary = Color(0xFFF3ECE0);
  static const Color surface = Color(0xFFFBF6EC);
  static const Color surfaceHigh = Color(0xFFFBF6EC);
  static const Color backgroundSurface = Color(0xFFFDFBF5);

  // Dual shadows for extruded 3D surfaces (Warm cream specular highlight & warm taupe drop shadow)
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color darkShadow = Color(0xFFD8CFBF);
  static const Color darkShadowSubtle = Color(0xFFE2D9CA);
  static const Color shadowStandard = Color(0x3BB0A494);
  static const Color shadowFloating = Color(0x4DA09482);
  static const Color glassShadow = shadowStandard;

  // Inset / Concave track & indentation colors
  static const Color insetTrack = Color(0xFFECE4D5);
  static const Color insetHighlight = Color(0xFFFFFFFF);
  static const Color insetShadow = Color(0xFFD1C7B5);

  // Deep espresso & warm charcoal tones for contrast
  static const Color midnightNavy = Color(0xFF282017);
  static const Color deepBlue = Color(0xFF3E3326);

  // Signature Coral / Orange Accent (gentle, warm coral)
  static const Color coral = Color(0xFFF06A4F);
  static const Color coralLight = Color(0xFFF5856C);
  static const Color coralDark = Color(0xFFDB553A);
  static const Color primaryCyan = coral;
  static const Color accent = coral;
  static const Color accentLight = coralLight;
  static const Color accentDark = coralDark;
  static const Color cyan = coral;
  static const Color lightCyan = coralLight;
  static const Color softCyan = coralLight;
  static const Color electricBlue = Color(0xFF5582CE);
  static const Color blue = Color(0xFF5582CE);
  static const Color silver = Color(0xFFFBF6EC);
  static const Color heartColor = Color(0xFFF25570);
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);

  // Rainbow 3D Spectrum (softened, harmonious)
  static const Color chartCoral = Color(0xFFF26868);
  static const Color chartOrange = Color(0xFFF58545);
  static const Color chartAmber = Color(0xFFF5C84C);
  static const Color chartGreen = Color(0xFF75CE24);
  static const Color chartTeal = Color(0xFF38C779);
  static const Color chartCyan = Color(0xFF20C7DC);

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
  static const Color glassPrimary = Color(0xFFFBF6EC);
  static const Color glassSecondary = Color(0xFFFBF6EC);
  static const Color glassElevated = Color(0xFFFBF6EC);
  static const Color glassSelected = Color(0xFFECE4D5);
  static const Color glassBlueTint = Color(0xFFF6EFE3);
  static const Color glassCyanTint = Color(0xFFF6EFE3);
  static const Color floatingGlass = Color(0xFFFBF6EC);
  static const Color sheetSurface = Color(0xFFFBF6EC);
  static const Color glassBackground = glassPrimary;

  // Overlays
  static const Color blurCyanOverlay = Color(0x10FF6444);
  static const Color blurBlueOverlay = Color(0x084A7BD0);
  static const Color blurNeutralOverlay = Color(0x10FFFFFF);
  static const Color blurSelectedOverlay = Color(0x20FF6444);

  // Subtle borders & specular highlights
  static const Color borderStandard = Color(0x185C4E3D);
  static const Color borderElevated = Color(0x245C4E3D);
  static const Color surfaceBorder = borderStandard;
  static const Color divider = Color(0x125C4E3D);
  static const Color borderActiveCyan = Color(0x80FF6444);
  static const Color specularHighlight = Color(0x60FFFFFF);
  static const Color glassBorder = borderStandard;
  static const Color glassBorderGlow = borderActiveCyan;
  static const Color glassBorderCyan = borderActiveCyan;

  static const Color shadowActiveCyan = Color(0x30FF6444);
  static const Color shadowCyanAccent = Color(0x25FF6444);

  // Card & Panel surfaces
  static const Color cardSurface = Color(0xFFFFFDF8);
  static const Color cardBorder = Color(0x165C4E3D);

  // High-legibility, warm typography (warm espresso charcoal)
  static const Color textPrimary = Color(0xFF282017);
  static const Color textSecondary = Color(0xFF655848);
  static const Color textTertiary = Color(0xFF918270);
  static const Color textMuted = textTertiary;

  // Floating dock & bottom navigation
  static const Color dockSurface = Color(0xFFFBF6EC);
  static const Color dockBorder = Color(0x165C4E3D);
  static const Color dockActiveSurface = Color(0xFFECE4D5);
  static const Color dockActiveBorder = Color(0x35FFFFFF);
  static const Color dockActiveGlow = Color(0x20F06A4F);
  static const Color dockInactive = Color(0xFF756755);

  // Playback control surfaces
  static const Color playControlSurface = Color(0xFFFBF6EC);
  static const Color playControlForeground = Color(0xFF282017);
  static const Color metallicAccent = Color(0xFFD8CFBF);

  // Atmosphere gradients
  static const Color nebulaBlue = Color(0x104A7BD0);
  static const Color nebulaCyan = Color(0x10FF6444);
  static const Color nebulaCoolBlue = Color(0x12D8CFBF);

  static const List<Color> gradientBlueCosmic = [
    Color(0xFFF3EFE6),
    Color(0xFFE5DDD0),
  ];
  static const List<Color> gradientElectricBlue = [
    Color(0xFFEDE8DE),
    Color(0xFFDFD6C7),
  ];
  static const List<Color> gradientCyanDepth = [
    Color(0xFFFBF3E8),
    Color(0xFFF2E2CF),
  ];
  static const List<Color> gradientBlueAura = [
    Color(0xFFF0EBE1),
    Color(0xFFE2D9CB),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFFF8F5EF),
    Color(0xFFECE6DC),
  ];
  static const List<Color> gradientStarlightTeal = [
    Color(0xFFEAF5EE),
    Color(0xFFD6EAE0),
  ];
  static const List<Color> gradientOceanBlue = [
    Color(0xFFEBF1F5),
    Color(0xFFD7E2E9),
  ];
  static const List<Color> gradientDarkOrbit = [
    Color(0xFFECE5DA),
    Color(0xFFDFD7CA),
  ];
  static const List<Color> gradientHero = [
    Color(0xFFFFFDF8),
    Color(0xFFFBF6EC),
    Color(0xFFEFE6D6),
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

  // Coordinated dark gradients for dark mode album art placeholders (pure black tones)
  static const List<List<Color>> allDarkGradients = [
    [Color(0xFF161616), Color(0xFF000000)],
    [Color(0xFF181818), Color(0xFF000000)],
    [Color(0xFF141414), Color(0xFF000000)],
    [Color(0xFF1A1A1A), Color(0xFF050505)],
    [Color(0xFF151515), Color(0xFF000000)],
    [Color(0xFF171717), Color(0xFF020202)],
    [Color(0xFF191919), Color(0xFF000000)],
    [Color(0xFF131313), Color(0xFF000000)],
  ];

  static List<Color> getGradientForId(int id) =>
      allGradients[id % allGradients.length];

  static List<Color> getGradientForIdTheme(int id, bool isDark) =>
      isDark
          ? allDarkGradients[id % allDarkGradients.length]
          : allGradients[id % allGradients.length];

  // Coordinated, restrained deep-black category tones
  static const List<Color> categoryOceanBlueDark = [
    Color(0xFF141F2B),
    Color(0xFF0A0F17),
  ];
  static const List<Color> categoryCyanDepthDark = [
    Color(0xFF241B18),
    Color(0xFF0E0F14),
  ];
  static const List<Color> categoryBlueAuraDark = [
    Color(0xFF12202B),
    Color(0xFF0A1017),
  ];
  static const List<Color> categoryMidnightSteelDark = [
    Color(0xFF1C2026),
    Color(0xFF0D0F13),
  ];
  static const List<Color> categoryElectricBlueDark = [
    Color(0xFF171E2D),
    Color(0xFF0B0F1A),
  ];
  static const List<Color> categoryBlueCosmicDark = [
    Color(0xFF182025),
    Color(0xFF0B0E11),
  ];

  static const List<Color> gradientHeroDark = [
    Color(0xFF121212),
    Color(0xFF060606),
    Color(0xFF000000),
  ];

  static List<Color> heroGradientOf(BuildContext context) =>
      isDark(context) ? gradientHeroDark : gradientHero;

  // Context-aware theme color helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.background : background;

  static Color backgroundSecondaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.backgroundSecondary : backgroundSecondary;

  static Color backgroundSurfaceOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.backgroundSurface : cardSurface;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.surface : surface;

  static Color cardSurfaceOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.cardSurface : cardSurface;

  static Color cardBorderOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.cardBorder : cardBorder;

  static Color lightShadowOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.lightShadow : lightShadow;

  static Color darkShadowOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.darkShadow : darkShadow;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textSecondary : textSecondary;

  static Color textTertiaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textTertiary : textTertiary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textMuted : textMuted;

  static Color borderStandardOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.borderStandard : borderStandard;

  static Color borderElevatedOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.borderElevated : borderElevated;

  static Color dividerOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.divider : divider;

  static Color insetTrackOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.insetTrack : insetTrack;

  static Color dockSurfaceOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.dockSurface : dockSurface;

  static Color dockBorderOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.dockBorder : dockBorder;

  static Color dockInactiveOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.dockInactive : dockInactive;

  static Color glassBackgroundOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.cardSurface : cardSurface;

  static Color glassSecondaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.backgroundSurface : cardSurface;

  static Color glassSelectedOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.dockActiveSurface : glassSelected;

  static Color glassBorderOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.borderStandard : glassBorder;

  static Color selectedSurfaceOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.dockActiveSurface : glassSelected;

  /// Consistent bottom clearance for scrollable views above the persistent
  /// floating bottom navigation dock and mini-player, accounting for safe-area insets.
  static double bottomClearanceOf(BuildContext context, {bool hasMiniPlayer = true}) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return (hasMiniPlayer ? 164.0 : 96.0) + bottomInset;
  }
}
