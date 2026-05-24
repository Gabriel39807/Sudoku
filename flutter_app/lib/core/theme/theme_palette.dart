import 'package:flutter/material.dart';

class AppPalette {
  final String label;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color border;
  final Color glow;

  final Color textPrimary;
  final Color textSecondary;

  final Color success;
  final Color warning;
  final Color danger;

  final Color buttonPrimary;
  final Color buttonSecondary;
  final Color buttonPressed;
  final Color buttonDisabled;

  final Color cardBackground;
  final Color cardBorder;

  final Color rewardGold;
  final Color rewardSoul;
  final Color rewardToken;

  final Color wheelAccent;
  final Color campaignAccent;

  const AppPalette({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.border,
    required this.glow,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.buttonPrimary,
    required this.buttonSecondary,
    required this.buttonPressed,
    required this.buttonDisabled,
    required this.cardBackground,
    required this.cardBorder,
    required this.rewardGold,
    required this.rewardSoul,
    required this.rewardToken,
    required this.wheelAccent,
    required this.campaignAccent,
  });

  AppPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? border,
    Color? glow,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? buttonPrimary,
    Color? buttonSecondary,
    Color? buttonPressed,
    Color? buttonDisabled,
    Color? cardBackground,
    Color? cardBorder,
    Color? rewardGold,
    Color? rewardSoul,
    Color? rewardToken,
    Color? wheelAccent,
    Color? campaignAccent,
  }) =>
      AppPalette(
        label: label,
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        accent: accent ?? this.accent,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        border: border ?? this.border,
        glow: glow ?? this.glow,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        buttonPrimary: buttonPrimary ?? this.buttonPrimary,
        buttonSecondary: buttonSecondary ?? this.buttonSecondary,
        buttonPressed: buttonPressed ?? this.buttonPressed,
        buttonDisabled: buttonDisabled ?? this.buttonDisabled,
        cardBackground: cardBackground ?? this.cardBackground,
        cardBorder: cardBorder ?? this.cardBorder,
        rewardGold: rewardGold ?? this.rewardGold,
        rewardSoul: rewardSoul ?? this.rewardSoul,
        rewardToken: rewardToken ?? this.rewardToken,
        wheelAccent: wheelAccent ?? this.wheelAccent,
        campaignAccent: campaignAccent ?? this.campaignAccent,
      );

  static const _white = Colors.white;
  static const _white70 = Color(0xB3FFFFFF);


  static const _surface = Color(0xFF1E1E1E);
  static const _background = Color(0xFF121212);
  static const _border = Color(0xFF2B2B2B);

  static final AppPalette classic = AppPalette(
    label: 'Classic',
    primary: const Color(0xFF6C63FF),
    secondary: const Color(0xFF3F3D9E),
    accent: const Color(0xFF4FC3F7),
    background: _background,
    surface: _surface,
    border: _border,
    glow: const Color(0xFF4FC3F7),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFEF5350),
    buttonPrimary: const Color(0xFF6C63FF),
    buttonSecondary: const Color(0xFF3F3D9E),
    buttonPressed: const Color(0xFF5A52E0),
    buttonDisabled: const Color(0xFF424242),
    cardBackground: _surface,
    cardBorder: _border,
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFF66BB6A),
    rewardToken: const Color(0xFF42A5F5),
    wheelAccent: const Color(0xFFFFA726),
    campaignAccent: const Color(0xFFD7B45A),
  );

  static final AppPalette inferno = AppPalette(
    label: 'Inferno',
    primary: const Color(0xFFFF4500),
    secondary: const Color(0xFF8B0000),
    accent: const Color(0xFFFFD700),
    background: const Color(0xFF1A0000),
    surface: const Color(0xFF2D0000),
    border: const Color(0xFF4A0000),
    glow: const Color(0xFFFF4500),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFEF5350),
    buttonPrimary: const Color(0xFFFF4500),
    buttonSecondary: const Color(0xFF8B0000),
    buttonPressed: const Color(0xFFCC3700),
    buttonDisabled: const Color(0xFF3D0000),
    cardBackground: const Color(0xFF2D0000),
    cardBorder: const Color(0xFF4A0000),
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFFFF6B6B),
    rewardToken: const Color(0xFFFF8C00),
    wheelAccent: const Color(0xFFFF6347),
    campaignAccent: const Color(0xFFFF4500),
  );

  static final AppPalette arcane = AppPalette(
    label: 'Arcane',
    primary: const Color(0xFFBB86FC),
    secondary: const Color(0xFF3700B3),
    accent: const Color(0xFFE040FB),
    background: const Color(0xFF0D001A),
    surface: const Color(0xFF1A0033),
    border: const Color(0xFF2D0059),
    glow: const Color(0xFFBB86FC),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFCF6679),
    buttonPrimary: const Color(0xFFBB86FC),
    buttonSecondary: const Color(0xFF3700B3),
    buttonPressed: const Color(0xFF9C64E0),
    buttonDisabled: const Color(0xFF1A0033),
    cardBackground: const Color(0xFF1A0033),
    cardBorder: const Color(0xFF2D0059),
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFFCE93D8),
    rewardToken: const Color(0xFFBB86FC),
    wheelAccent: const Color(0xFFE040FB),
    campaignAccent: const Color(0xFFBB86FC),
  );

  static final AppPalette gold = AppPalette(
    label: 'Gold',
    primary: const Color(0xFFD4AF37),
    secondary: const Color(0xFF996515),
    accent: const Color(0xFFFFF8DC),
    background: const Color(0xFF1A1500),
    surface: const Color(0xFF2D2600),
    border: const Color(0xFF4A3D00),
    glow: const Color(0xFFFFD700),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFEF5350),
    buttonPrimary: const Color(0xFFD4AF37),
    buttonSecondary: const Color(0xFF996515),
    buttonPressed: const Color(0xFFB8960A),
    buttonDisabled: const Color(0xFF2D2600),
    cardBackground: const Color(0xFF2D2600),
    cardBorder: const Color(0xFF4A3D00),
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFFFFF8DC),
    rewardToken: const Color(0xFFD4AF37),
    wheelAccent: const Color(0xFFFFD700),
    campaignAccent: const Color(0xFFD4AF37),
  );

  static final AppPalette emerald = AppPalette(
    label: 'Emerald',
    primary: const Color(0xFF00B894),
    secondary: const Color(0xFF00695C),
    accent: const Color(0xFF55EFC4),
    background: const Color(0xFF002B1F),
    surface: const Color(0xFF004D37),
    border: const Color(0xFF006B4D),
    glow: const Color(0xFF00B894),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFEF5350),
    buttonPrimary: const Color(0xFF00B894),
    buttonSecondary: const Color(0xFF00695C),
    buttonPressed: const Color(0xFF009B7A),
    buttonDisabled: const Color(0xFF002B1F),
    cardBackground: const Color(0xFF004D37),
    cardBorder: const Color(0xFF006B4D),
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFF55EFC4),
    rewardToken: const Color(0xFF00B894),
    wheelAccent: const Color(0xFF55EFC4),
    campaignAccent: const Color(0xFF00B894),
  );

  static final AppPalette ice = AppPalette(
    label: 'Ice',
    primary: const Color(0xFF81ECEC),
    secondary: const Color(0xFF00CED1),
    accent: const Color(0xFFE0F7FA),
    background: const Color(0xFF001A1A),
    surface: const Color(0xFF003333),
    border: const Color(0xFF006666),
    glow: const Color(0xFF81ECEC),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFEF5350),
    buttonPrimary: const Color(0xFF81ECEC),
    buttonSecondary: const Color(0xFF00CED1),
    buttonPressed: const Color(0xFF00B4B4),
    buttonDisabled: const Color(0xFF002222),
    cardBackground: const Color(0xFF003333),
    cardBorder: const Color(0xFF006666),
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFFE0F7FA),
    rewardToken: const Color(0xFF81ECEC),
    wheelAccent: const Color(0xFF00CED1),
    campaignAccent: const Color(0xFF81ECEC),
  );

  static final AppPalette blood = AppPalette(
    label: 'Blood',
    primary: const Color(0xFFCF6679),
    secondary: const Color(0xFF8B0000),
    accent: const Color(0xFFFF5252),
    background: const Color(0xFF1A0000),
    surface: const Color(0xFF2D0000),
    border: const Color(0xFF5C0000),
    glow: const Color(0xFFFF1744),
    textPrimary: _white,
    textSecondary: _white70,
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFA726),
    danger: const Color(0xFFCF6679),
    buttonPrimary: const Color(0xFFCF6679),
    buttonSecondary: const Color(0xFF8B0000),
    buttonPressed: const Color(0xFFB84C60),
    buttonDisabled: const Color(0xFF2D0000),
    cardBackground: const Color(0xFF2D0000),
    cardBorder: const Color(0xFF5C0000),
    rewardGold: const Color(0xFFFFD700),
    rewardSoul: const Color(0xFFFF5252),
    rewardToken: const Color(0xFFCF6679),
    wheelAccent: const Color(0xFFFF1744),
    campaignAccent: const Color(0xFFCF6679),
  );

  static final List<AppPalette> all = [classic, inferno, arcane, gold, emerald, ice, blood];

  static AppPalette fromIndex(int index) => all[index.clamp(0, all.length - 1)];
}
