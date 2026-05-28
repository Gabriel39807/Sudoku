import 'package:flutter/material.dart';
import 'avatar_def.dart';

class AvatarFrameDef {
  final String id;
  final String name;
  final int gemCost;
  final AvatarRarity rarity;
  final Color primaryColor;
  final Color secondaryColor;
  final double thickness;
  final double glowRadius;

  const AvatarFrameDef({
    required this.id,
    required this.name,
    required this.gemCost,
    required this.rarity,
    required this.primaryColor,
    required this.secondaryColor,
    this.thickness = 3.0,
    this.glowRadius = 0.0,
  });

  bool get isAnimated =>
      rarity == AvatarRarity.mythic || rarity == AvatarRarity.legendary;

  bool get hasGlow => glowRadius > 0;
}

class AvatarFrameCatalog {
  static const List<AvatarFrameDef> all = [
    // ── NONE (no frame) ──────────────────────────────────────────────────
    AvatarFrameDef(
      id: 'none',
      name: 'Sin marco',
      gemCost: 0,
      rarity: AvatarRarity.common,
      primaryColor: Colors.transparent,
      secondaryColor: Colors.transparent,
      thickness: 0,
      glowRadius: 0,
    ),

    // ── COMMON ───────────────────────────────────────────────────────────
    AvatarFrameDef(
      id: 'frame_metallic',
      name: 'Metálico',
      gemCost: 450,
      rarity: AvatarRarity.common,
      primaryColor: Color(0xFFC0C0C0),
      secondaryColor: Color(0xFF808080),
      thickness: 3,
      glowRadius: 0,
    ),
    AvatarFrameDef(
      id: 'frame_minimal',
      name: 'Minimal',
      gemCost: 500,
      rarity: AvatarRarity.common,
      primaryColor: Color(0xFFFFFFFF),
      secondaryColor: Color(0xFFCCCCCC),
      thickness: 2,
      glowRadius: 0,
    ),

    // ── RARE ─────────────────────────────────────────────────────────────
    AvatarFrameDef(
      id: 'frame_energy',
      name: 'Energía',
      gemCost: 700,
      rarity: AvatarRarity.rare,
      primaryColor: Color(0xFF00BFFF),
      secondaryColor: Color(0xFF1E90FF),
      thickness: 3.5,
      glowRadius: 6,
    ),
    AvatarFrameDef(
      id: 'frame_crystal',
      name: 'Cristal',
      gemCost: 900,
      rarity: AvatarRarity.rare,
      primaryColor: Color(0xFFFF69B4),
      secondaryColor: Color(0xFFFF1493),
      thickness: 3.5,
      glowRadius: 6,
    ),

    // ── EPIC ─────────────────────────────────────────────────────────────
    AvatarFrameDef(
      id: 'frame_neon',
      name: 'Neón',
      gemCost: 1200,
      rarity: AvatarRarity.epic,
      primaryColor: Color(0xFF39FF14),
      secondaryColor: Color(0xFF00D4FF),
      thickness: 4,
      glowRadius: 10,
    ),
    AvatarFrameDef(
      id: 'frame_cosmic',
      name: 'Anillo Cósmico',
      gemCost: 1600,
      rarity: AvatarRarity.epic,
      primaryColor: Color(0xFF9B59B6),
      secondaryColor: Color(0xFF4B0082),
      thickness: 4.5,
      glowRadius: 12,
    ),

    // ── LEGENDARY ────────────────────────────────────────────────────────
    AvatarFrameDef(
      id: 'frame_dragon',
      name: 'Aura de Dragón',
      gemCost: 2000,
      rarity: AvatarRarity.legendary,
      primaryColor: Color(0xFFFF4500),
      secondaryColor: Color(0xFFFFD700),
      thickness: 5,
      glowRadius: 16,
    ),
    AvatarFrameDef(
      id: 'frame_phoenix',
      name: 'Llama de Fénix',
      gemCost: 2200,
      rarity: AvatarRarity.legendary,
      primaryColor: Color(0xFFFF6347),
      secondaryColor: Color(0xFFFFD700),
      thickness: 5,
      glowRadius: 18,
    ),

    // ── MYTHIC ───────────────────────────────────────────────────────────
    AvatarFrameDef(
      id: 'frame_void',
      name: 'Orbital del Vacío',
      gemCost: 3000,
      rarity: AvatarRarity.mythic,
      primaryColor: Color(0xFF000000),
      secondaryColor: Color(0xFFE91E63),
      thickness: 6,
      glowRadius: 22,
    ),
    AvatarFrameDef(
      id: 'frame_aether',
      name: 'Halo Etéreo',
      gemCost: 3500,
      rarity: AvatarRarity.mythic,
      primaryColor: Color(0xFFDDA0DD),
      secondaryColor: Color(0xFF87CEEB),
      thickness: 5.5,
      glowRadius: 20,
    ),
  ];

  static AvatarFrameDef? byId(String id) {
    try {
      return all.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  static const String defaultId = 'none';

  static AvatarFrameDef get defaultFrame => all.first;
}
