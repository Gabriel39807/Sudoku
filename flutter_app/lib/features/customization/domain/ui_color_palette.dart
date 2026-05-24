import 'package:flutter/material.dart';

enum UIColorPalette {
  classicBlue(
    label: 'Classic Blue',
    primary: Color(0xFF6C63FF),
    secondary: Color(0xFF3F3D9E),
    accent: Color(0xFF4FC3F7),
    buttonGradientStart: Color(0xFF6C63FF),
    buttonGradientEnd: Color(0xFF3F3D9E),
    glow: Color(0xFF4FC3F7),
  ),
  emerald(
    label: 'Emerald',
    primary: Color(0xFF00B894),
    secondary: Color(0xFF00695C),
    accent: Color(0xFF55EFC4),
    buttonGradientStart: Color(0xFF00B894),
    buttonGradientEnd: Color(0xFF00695C),
    glow: Color(0xFF55EFC4),
  ),
  crimson(
    label: 'Crimson',
    primary: Color(0xFFE74C3C),
    secondary: Color(0xFF922B21),
    accent: Color(0xFFFF7979),
    buttonGradientStart: Color(0xFFE74C3C),
    buttonGradientEnd: Color(0xFF922B21),
    glow: Color(0xFFFF7979),
  ),
  golden(
    label: 'Golden',
    primary: Color(0xFFF39C12),
    secondary: Color(0xFFD4AC0D),
    accent: Color(0xFFF7DC6F),
    buttonGradientStart: Color(0xFFF39C12),
    buttonGradientEnd: Color(0xFFD4AC0D),
    glow: Color(0xFFF7DC6F),
  ),
  crystal(
    label: 'Crystal',
    primary: Color(0xFF81ECEC),
    secondary: Color(0xFF00CED1),
    accent: Color(0xFFE0F7FA),
    buttonGradientStart: Color(0xFF81ECEC),
    buttonGradientEnd: Color(0xFF00CED1),
    glow: Color(0xFFE0F7FA),
  ),
  purpleNeon(
    label: 'Purple Neon',
    primary: Color(0xFFBB86FC),
    secondary: Color(0xFF6200EE),
    accent: Color(0xFFE040FB),
    buttonGradientStart: Color(0xFFBB86FC),
    buttonGradientEnd: Color(0xFF6200EE),
    glow: Color(0xFFE040FB),
  ),
  darkMythic(
    label: 'Dark Mythic',
    primary: Color(0xFFCF6679),
    secondary: Color(0xFF121212),
    accent: Color(0xFFB00020),
    buttonGradientStart: Color(0xFFCF6679),
    buttonGradientEnd: Color(0xFF121212),
    glow: Color(0xFFB00020),
  ),
  forest(
    label: 'Forest',
    primary: Color(0xFF27AE60),
    secondary: Color(0xFF1E8449),
    accent: Color(0xFF82E0AA),
    buttonGradientStart: Color(0xFF27AE60),
    buttonGradientEnd: Color(0xFF1E8449),
    glow: Color(0xFF82E0AA),
  );

  final String label;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color buttonGradientStart;
  final Color buttonGradientEnd;
  final Color glow;

  const UIColorPalette({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.buttonGradientStart,
    required this.buttonGradientEnd,
    required this.glow,
  });

  static const defaultPalette = UIColorPalette.classicBlue;
}
