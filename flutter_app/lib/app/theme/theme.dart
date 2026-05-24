import 'package:flutter/material.dart';
import '../../core/theme/theme_palette.dart';

ThemeData buildTheme(AppPalette palette) {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: palette.background,
    primaryColor: palette.primary,
    colorScheme: ColorScheme.dark(
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.surface,
      error: palette.danger,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: palette.cardBackground,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.buttonPrimary,
        foregroundColor: palette.textPrimary,
        disabledBackgroundColor: palette.buttonDisabled,
        disabledForegroundColor: palette.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        ),
    dividerColor: palette.border,
    focusColor: palette.accent,
    highlightColor: palette.glow.withValues(alpha: 0.1),
    splashColor: palette.glow.withValues(alpha: 0.05),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surface,
      contentTextStyle: TextStyle(color: palette.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: palette.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.primary),
      ),
      labelStyle: TextStyle(color: palette.textSecondary),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
      linearTrackColor: palette.border,
    ),
    iconTheme: IconThemeData(color: palette.textPrimary),
    dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
  );
}
