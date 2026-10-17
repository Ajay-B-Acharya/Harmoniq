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
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          surface: AppColors.background,
          primary: AppColors.coral,
          onPrimary: Colors.white,
          secondary: AppColors.coralLight,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          outline: AppColors.darkShadow,
        ),
        splashFactory: InkSparkle.splashFactory,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
          bodySmall: TextStyle(
            color: AppColors.textTertiary,
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
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.darkShadow, width: 1.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.background,
          selectedColor: AppColors.insetTrack,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSecondary,
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
            color: AppColors.textTertiary,
            fontSize: 13.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.background,
          showDragHandle: true,
          dragHandleColor: AppColors.darkShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.coral,
          inactiveTrackColor:
              AppColors.darkShadow.withValues(alpha: 0.35),
          thumbColor: Colors.white,
          overlayColor: AppColors.coral.withValues(alpha: 0.16),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        cardTheme: CardThemeData(
          color: AppColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder, width: 1.0),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF7E8F9E);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.coral;
            }
            return const Color(0xFFD4DCE8);
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppDarkColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppDarkColors.background,
          primary: AppColors.coral,
          onPrimary: Colors.white,
          secondary: AppColors.coralLight,
          onSecondary: Colors.white,
          onSurface: AppDarkColors.textPrimary,
          outline: AppDarkColors.darkShadow,
        ),
        splashFactory: InkSparkle.splashFactory,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppDarkColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          headlineMedium: TextStyle(
            color: AppDarkColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          titleLarge: TextStyle(
            color: AppDarkColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: AppDarkColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppDarkColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: AppDarkColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
          bodySmall: TextStyle(
            color: AppDarkColors.textTertiary,
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
            backgroundColor: AppDarkColors.background,
            foregroundColor: AppDarkColors.textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppDarkColors.textPrimary,
            side: const BorderSide(color: AppDarkColors.lightShadow, width: 1.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppDarkColors.background,
          selectedColor: AppDarkColors.lightShadow,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(
            color: AppDarkColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppDarkColors.backgroundSecondary,
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
            color: AppDarkColors.textTertiary,
            fontSize: 13.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppDarkColors.background,
          showDragHandle: true,
          dragHandleColor: AppDarkColors.lightShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.coral,
          inactiveTrackColor:
              AppDarkColors.lightShadow.withValues(alpha: 0.35),
          thumbColor: Colors.white,
          overlayColor: AppColors.coral.withValues(alpha: 0.16),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        ),
        iconTheme: const IconThemeData(color: AppDarkColors.textPrimary),
        cardTheme: CardThemeData(
          color: AppDarkColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppDarkColors.cardBorder, width: 1.0),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF94A3B8);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.coral;
            }
            return AppDarkColors.insetTrack;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      );

  static ThemeData get theme =>
      ThemeController.instance.isDark ? darkTheme : lightTheme;
}
