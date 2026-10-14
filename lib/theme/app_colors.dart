import 'package:flutter/material.dart';

/// SPATIAL UI — COMPLETE VISUAL MATERIAL & LIGHTING SYSTEM DESIGN TOKENS
class AppColors {
  // ── 1. BACKGROUND — DARK NEBULA ATMOSPHERE ───────────────────────────────
  /// Primary background: #05060A
  static const Color background = Color(0xFF05060A);

  /// Secondary background: #080B16
  static const Color backgroundSecondary = Color(0xFF080B16);

  /// Midnight navy: #0B0E1A
  static const Color midnightNavy = Color(0xFF0B0E1A);

  /// Deep indigo atmosphere: #100D20
  static const Color deepBlueViolet = Color(0xFF100D20);

  /// Dark purple atmospheric tone: #1A1230
  static const Color darkPurpleAtmosphere = Color(0xFF1A1230);

  /// Atmospheric gradient colors (low-opacity lighting)
  static const Color nebulaViolet = Color(0x1A7C3AED); // rgba(124, 58, 237, 0.10)
  static const Color nebulaBlue = Color(0x123B82F6); // rgba(59, 130, 246, 0.07)
  static const Color nebulaCyan = Color(0x0606B6D4); // rgba(6, 182, 212, 0.025)
  static const Color nebulaMagenta = Color(0x09EC4899); // rgba(236, 72, 153, 0.035)

  /// Surface fallbacks
  static const Color backgroundSurface = Color(0xFF0D0F1B);
  static const Color surfaceHigh = Color(0xFF141726);
  static const Color surfaceBorder = Color(0x24FFFFFF); // rgba(255, 255, 255, 0.14)

  // ── 2. GLASS MATERIAL — TRANSPARENCY AND SURFACE COLOR ────────────────────
  /// Primary glass: rgba(255, 255, 255, 0.025)
  static const Color glassPrimary = Color(0x06FFFFFF);

  /// Secondary glass: rgba(255, 255, 255, 0.040)
  static const Color glassSecondary = Color(0x0AFFFFFF);

  /// Elevated glass: rgba(255, 255, 255, 0.055)
  static const Color glassElevated = Color(0x0EFFFFFF);

  /// Selected glass: rgba(168, 85, 247, 0.080)
  static const Color glassSelected = Color(0x14A855F7);

  /// Subtle blue-tinted glass: rgba(96, 165, 250, 0.035)
  static const Color glassBlueTint = Color(0x0960A5FA);

  /// Subtle violet-tinted glass: rgba(168, 85, 247, 0.045)
  static const Color glassVioletTint = Color(0x0CA855F7);

  /// Aliases for backward compatibility
  static const Color glassBackground = glassPrimary;

  // ── 3. BLUR SYSTEM OVERLAYS ──────────────────────────────────────────────
  static const Color blurVioletOverlay = Color(0x09A855F7); // rgba(168, 85, 247, 0.035)
  static const Color blurBlueOverlay = Color(0x0660A5FA); // rgba(96, 165, 250, 0.025)
  static const Color blurNeutralOverlay = Color(0x06FFFFFF); // rgba(255, 255, 255, 0.025)
  static const Color blurSelectedOverlay = Color(0x13A855F7); // rgba(168, 85, 247, 0.075)

  // ── 4. BORDER SYSTEM — PHYSICAL GLASS EDGES ──────────────────────────────
  /// Standard glass border: rgba(255, 255, 255, 0.14)
  static const Color borderStandard = Color(0x24FFFFFF);

  /// Elevated glass border: rgba(255, 255, 255, 0.20)
  static const Color borderElevated = Color(0x33FFFFFF);

  /// Subtle divider: rgba(255, 255, 255, 0.09)
  static const Color divider = Color(0x17FFFFFF);

  /// Active violet border: rgba(168, 85, 247, 0.50)
  static const Color borderActiveViolet = Color(0x80A855F7);

  /// Active cyan border: rgba(6, 182, 212, 0.40)
  static const Color borderActiveCyan = Color(0x6606B6D4);

  /// Top-edge specular highlight: rgba(255, 255, 255, 0.22)
  static const Color specularHighlight = Color(0x38FFFFFF);

  /// Aliases for backward compatibility
  static const Color glassBorder = borderStandard;
  static const Color glassBorderGlow = borderActiveViolet;
  static const Color glassBorderCyan = borderActiveCyan;

  // ── 5. SHADOW SYSTEM — SPATIAL ELEVATION ──────────────────────────────────
  /// Standard glass shadow: rgba(0, 0, 0, 0.18)
  static const Color shadowStandard = Color(0x2E000000);

  /// Floating panel shadow: rgba(0, 0, 0, 0.28)
  static const Color shadowFloating = Color(0x47000000);

  /// Active violet ambient shadow: rgba(168, 85, 247, 0.16)
  static const Color shadowActiveViolet = Color(0x29A855F7);

  /// Cyan accent shadow: rgba(6, 182, 212, 0.12)
  static const Color shadowCyanAccent = Color(0x1F06B6D4);

  /// Aliases for backward compatibility
  static const Color glassShadow = shadowStandard;

  // ── 6. ACCENT COLORS AND CONTROLLED GLOW ──────────────────────────────────
  /// Primary violet: #A855F7
  static const Color primaryViolet = Color(0xFFA855F7);

  /// Light violet: #C084FC
  static const Color lightViolet = Color(0xFFC084FC);

  /// Deep violet: #7C3AED
  static const Color deepViolet = Color(0xFF7C3AED);

  /// Neon pink: #EC4899
  static const Color neonPink = Color(0xFFEC4899);

  /// Cyan: #06B6D4
  static const Color cyan = Color(0xFF06B6D4);

  /// Light cyan: #67E8F9
  static const Color lightCyan = Color(0xFF67E8F9);

  /// Amber: #F59E0B
  static const Color amber = Color(0xFFF59E0B);

  /// Semantic UI mappings
  static const Color accent = primaryViolet;
  static const Color accentLight = lightViolet;
  static const Color accentDark = deepViolet;
  static const Color electricBlue = cyan;
  static const Color softCyan = lightCyan;
  static const Color heartColor = neonPink;
  static const Color metallicAccent = Color(0xFF94A3B8);

  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);

  // ── 6. TYPOGRAPHY ────────────────────────────────────────────────────────
  /// Primary text: #F8FAFC
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Secondary text: rgba(248, 250, 252, 0.70)
  static const Color textSecondary = Color(0xB3F8FAFC);

  /// Tertiary text: rgba(248, 250, 252, 0.45)
  static const Color textTertiary = Color(0x73F8FAFC);

  /// Alias for backward compatibility
  static const Color textMuted = textTertiary;

  // ── 8. FLOATING NAVIGATION DOCK TOKENS ────────────────────────────────────
  /// Dock surface: rgba(15, 17, 30, 0.62)
  static const Color dockSurface = Color(0x9E0F111E);

  /// Dock border: rgba(255, 255, 255, 0.16)
  static const Color dockBorder = Color(0x29FFFFFF);

  /// Active item surface: rgba(168, 85, 247, 0.13)
  static const Color dockActiveSurface = Color(0x21A855F7);

  /// Active item border: rgba(168, 85, 247, 0.45)
  static const Color dockActiveBorder = Color(0x73A855F7);

  /// Active item ambient glow: rgba(168, 85, 247, 0.16)
  static const Color dockActiveGlow = Color(0x29A855F7);

  /// Inactive item icon/label: rgba(248, 250, 252, 0.60)
  static const Color dockInactive = Color(0x99F8FAFC);

  // ── 7. ARTWORK GRADIENTS (RICH DEEP NEBULA TONES) ─────────────────────────
  static const List<Color> gradientVioletCosmic = [
    Color(0xFF2E1A47),
    Color(0xFF120D22),
  ];
  static const List<Color> gradientElectricIndigo = [
    Color(0xFF1B2A5E),
    Color(0xFF0D1429),
  ];
  static const List<Color> gradientCyanDepth = [
    Color(0xFF103B47),
    Color(0xFF081C24),
  ];
  static const List<Color> gradientPurpleAura = [
    Color(0xFF381A54),
    Color(0xFF170924),
  ];
  static const List<Color> gradientMidnightSteel = [
    Color(0xFF1B2438),
    Color(0xFF0E1320),
  ];
  static const List<Color> gradientStarlightTeal = [
    Color(0xFF113E42),
    Color(0xFF081D21),
  ];
  static const List<Color> gradientNebulaRose = [
    Color(0xFF421B35),
    Color(0xFF1B0715),
  ];
  static const List<Color> gradientDarkOrbit = [
    Color(0xFF1F2436),
    Color(0xFF0C101A),
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
