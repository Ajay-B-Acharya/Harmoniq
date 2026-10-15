import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'theme_controller.dart';

/// Neumorphism & Soft 3D App Theme
///
/// Configures monochromatic soft canvas, crisp slate typography,
/// tactile button elevation, and signature coral accents for both Light and Dark modes.
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE8ECF2),
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFE8ECF2),
          primary: AppColors.coral,
          onPrimary: Colors.white,
          secondary: AppColors.coralLight,
          onSecondary: Colors.white,
          onSurface: Color(0xFF202A36),
          outline: Color(0xFFB8C5D6),
        ),
        splashFactory: InkSparkle.splashFactory,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF202A36),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF202A36),
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF202A36),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF202A36),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF202A36),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF7A8B9E),
            fontSize: 13,
            height: 1.45,
          ),
          bodySmall: TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8ECF2),
            foregroundColor: const Color(0xFF202A36),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF202A36),
            side: const BorderSide(color: Color(0xFFB8C5D6), width: 1.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE8ECF2),
          selectedColor: const Color(0xFFDFE5ED),
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(
            color: Color(0xFF202A36),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE2E7ED),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 13.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFE8ECF2),
          showDragHandle: true,
          dragHandleColor: Color(0xFFB8C5D6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.coral,
          inactiveTrackColor:
              const Color(0xFFB8C5D6).withValues(alpha: 0.35),
          thumbColor: Colors.white,
          overlayColor: AppColors.coral.withValues(alpha: 0.16),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF202A36)),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E222B),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1E222B),
          primary: AppColors.coral,
          onPrimary: Colors.white,
          secondary: AppColors.coralLight,
          onSecondary: Colors.white,
          onSurface: Color(0xFFF1F5F9),
          outline: Color(0xFF0F1217),
        ),
        splashFactory: InkSparkle.splashFactory,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          titleLarge: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            height: 1.45,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E222B),
            foregroundColor: const Color(0xFFF1F5F9),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF1F5F9),
            side: const BorderSide(color: Color(0xFF282F3C), width: 1.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1E222B),
          selectedColor: const Color(0xFF282F3C),
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF181B22),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E222B),
          showDragHandle: true,
          dragHandleColor: Color(0xFF282F3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.coral,
          inactiveTrackColor:
              const Color(0xFF282F3C).withValues(alpha: 0.35),
          thumbColor: Colors.white,
          overlayColor: AppColors.coral.withValues(alpha: 0.16),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
      );

  static ThemeData get theme =>
      ThemeController.instance.isDark ? darkTheme : lightTheme;
}
