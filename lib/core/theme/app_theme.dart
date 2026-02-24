import 'package:flutter/material.dart';

import 'rpg_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const primary = Color(0xFF8B80F0); // soft violet — primary accent
    const secondary = Color(0xFF5C6BC0); // indigo
    const error = Color(0xFFCF6679);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: RpgColors.pageBg,
      secondary: secondary,
      onSecondary: RpgColors.textPrimary,
      error: error,
      onError: RpgColors.pageBg,
      surface: RpgColors.panelBg,
      onSurface: RpgColors.textPrimary,
      surfaceContainerHighest: RpgColors.panelBgAlt,
      outline: RpgColors.border,
      outlineVariant: RpgColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RpgColors.pageBg,
      canvasColor: RpgColors.panelBg,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: RpgColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.8,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: RpgColors.panelBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: RpgColors.border),
        ),
      ),

      // ── NavigationBar ───────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: RpgColors.panelBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? primary : RpgColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? primary : RpgColors.textMuted,
            size: 22,
          );
        }),
      ),

      // ── BottomSheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RpgColors.panelBgAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: RpgColors.panelBgAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: RpgColors.border),
        ),
        titleTextStyle: const TextStyle(
          color: RpgColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: RpgColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // ── Input ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RpgColors.pageBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: RpgColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: RpgColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: RpgColors.textSecondary),
        hintStyle: const TextStyle(color: RpgColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),

      // ── FilledButton ────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: RpgColors.pageBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RpgColors.accent,
          side: const BorderSide(color: RpgColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ── TextButton ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RpgColors.textSecondary,
        ),
      ),

      // ── IconButton ──────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: RpgColors.textMuted,
        ),
      ),

      // ── ChoiceChip ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: RpgColors.panelBg,
        selectedColor: primary.withValues(alpha: 0.18),
        side: const BorderSide(color: RpgColors.border),
        labelStyle: const TextStyle(
          color: RpgColors.textSecondary,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: RpgColors.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        checkmarkColor: primary,
      ),

      // ── SnackBar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: RpgColors.panelBgAlt,
        contentTextStyle: const TextStyle(color: RpgColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: RpgColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: RpgColors.divider,
        thickness: 1,
      ),

      // ── ProgressIndicator ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: RpgColors.progressTrack,
      ),

      // ── Text ────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: RpgColors.textPrimary),
        displayMedium: TextStyle(color: RpgColors.textPrimary),
        displaySmall: TextStyle(color: RpgColors.textPrimary),
        headlineLarge: TextStyle(color: RpgColors.textPrimary),
        headlineMedium: TextStyle(color: RpgColors.textPrimary),
        headlineSmall: TextStyle(color: RpgColors.textPrimary),
        titleLarge: TextStyle(color: RpgColors.textPrimary),
        titleMedium: TextStyle(color: RpgColors.textPrimary),
        titleSmall: TextStyle(color: RpgColors.textPrimary),
        bodyLarge: TextStyle(color: RpgColors.textPrimary),
        bodyMedium: TextStyle(color: RpgColors.textPrimary),
        bodySmall: TextStyle(color: RpgColors.textSecondary),
        labelLarge: TextStyle(color: RpgColors.textPrimary),
        labelMedium: TextStyle(color: RpgColors.textSecondary),
        labelSmall: TextStyle(color: RpgColors.textMuted),
      ),
    );
  }
}
