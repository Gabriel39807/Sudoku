import 'package:flutter/material.dart';

enum GameBackgroundTheme {
  darkSpace(
    id: 'dark_space',
    label: 'Deep Space',
    gradientColors: [Color(0xFF0D1117), Color(0xFF1A1A2E)],
    assetPath: null,
    lockedByDefault: false,
  ),
  midnightBlue(
    id: 'midnight_blue',
    label: 'Midnight Blue',
    gradientColors: [Color(0xFF0C1445), Color(0xFF1A237E)],
    assetPath: null,
    lockedByDefault: false,
  ),
  emeraldMist(
    id: 'emerald_mist',
    label: 'Emerald Mist',
    gradientColors: [Color(0xFF004D40), Color(0xFF1B5E20)],
    assetPath: null,
    lockedByDefault: false,
  ),
  royalCrimson(
    id: 'royal_crimson',
    label: 'Royal Crimson',
    gradientColors: [Color(0xFF4A0000), Color(0xFF880E4F)],
    assetPath: null,
    lockedByDefault: false,
  ),
  warmAmber(
    id: 'warm_amber',
    label: 'Warm Amber',
    gradientColors: [Color(0xFF3E2723), Color(0xFFE65100)],
    assetPath: null,
    lockedByDefault: false,
  ),
  cosmicPurple(
    id: 'cosmic_purple',
    label: 'Cosmic Purple',
    gradientColors: [Color(0xFF1A0033), Color(0xFF4A148C)],
    assetPath: null,
    lockedByDefault: true,
    unlockCost: 500,
  ),
  arcticDawn(
    id: 'arctic_dawn',
    label: 'Arctic Dawn',
    gradientColors: [Color(0xFF1A237E), Color(0xFF81D4FA)],
    assetPath: null,
    lockedByDefault: true,
    unlockCost: 300,
  ),
  sunsetBlaze(
    id: 'sunset_blaze',
    label: 'Sunset Blaze',
    gradientColors: [Color(0xFF1A0000), Color(0xFFFF6F00)],
    assetPath: null,
    lockedByDefault: true,
    unlockCost: 400,
  );

  final String id;
  final String label;
  final List<Color> gradientColors;
  final String? assetPath;
  final bool lockedByDefault;
  final int unlockCost;

  const GameBackgroundTheme({
    required this.id,
    required this.label,
    required this.gradientColors,
    this.assetPath,
    this.lockedByDefault = false,
    this.unlockCost = 0,
  });

  static const defaultBackground = GameBackgroundTheme.darkSpace;
}
