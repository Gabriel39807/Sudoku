import 'package:flutter/material.dart';

enum AvatarRarity {
  common,
  rare,
  epic,
  legendary,
  mythic;

  String get label {
    switch (this) {
      case AvatarRarity.common:
        return 'COMÚN';
      case AvatarRarity.rare:
        return 'RARO';
      case AvatarRarity.epic:
        return 'ÉPICO';
      case AvatarRarity.legendary:
        return 'LEGENDARIO';
      case AvatarRarity.mythic:
        return 'MÍTICO';
    }
  }

  String get labelShort {
    switch (this) {
      case AvatarRarity.common:
        return 'C';
      case AvatarRarity.rare:
        return 'R';
      case AvatarRarity.epic:
        return 'E';
      case AvatarRarity.legendary:
        return 'L';
      case AvatarRarity.mythic:
        return 'M';
    }
  }

  Color get color {
    switch (this) {
      case AvatarRarity.common:
        return Colors.white54;
      case AvatarRarity.rare:
        return const Color(0xFF3498DB);
      case AvatarRarity.epic:
        return const Color(0xFF9B59B6);
      case AvatarRarity.legendary:
        return const Color(0xFFFF6B35);
      case AvatarRarity.mythic:
        return const Color(0xFFE91E63);
    }
  }

  Color get glowColor {
    switch (this) {
      case AvatarRarity.common:
        return Colors.white12;
      case AvatarRarity.rare:
        return const Color(0xFF3498DB);
      case AvatarRarity.epic:
        return const Color(0xFF9B59B6);
      case AvatarRarity.legendary:
        return const Color(0xFFFF6B35);
      case AvatarRarity.mythic:
        return const Color(0xFFE91E63);
    }
  }
}

class AvatarDef {
  final String id;
  final String name;
  final int gemCost;
  final AvatarRarity rarity;
  final IconData icon;
  final Color color1;
  final Color color2;
  final String description;
  final String? unlockHint;

  const AvatarDef({
    required this.id,
    required this.name,
    required this.gemCost,
    required this.rarity,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.description,
    this.unlockHint,
  });

  bool get isAnimated => rarity == AvatarRarity.mythic || rarity == AvatarRarity.legendary;
}

class AvatarCatalog {
  static const List<AvatarDef> all = [
    // ── COMMON ───────────────────────────────────────────────────────────
    AvatarDef(
      id: 'geo_circle',
      name: 'Círculo',
      gemCost: 100,
      rarity: AvatarRarity.common,
      icon: Icons.circle,
      color1: Color(0xFF4A90D9),
      color2: Color(0xFF357ABD),
      description: 'Forma geométrica básica',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'geo_square',
      name: 'Cuadrado',
      gemCost: 100,
      rarity: AvatarRarity.common,
      icon: Icons.square,
      color1: Color(0xFF50C878),
      color2: Color(0xFF3CB371),
      description: 'Símbolo de estabilidad',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'geo_triangle',
      name: 'Triángulo',
      gemCost: 120,
      rarity: AvatarRarity.common,
      icon: Icons.change_history,
      color1: Color(0xFFBA55D3),
      color2: Color(0xFF9932CC),
      description: 'Fuerza en tres lados',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'geo_hex',
      name: 'Hexágono',
      gemCost: 130,
      rarity: AvatarRarity.common,
      icon: Icons.grid_view,
      color1: Color(0xFF20B2AA),
      color2: Color(0xFF008B8B),
      description: 'El polígono perfecto',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'geo_diamond',
      name: 'Diamante',
      gemCost: 150,
      rarity: AvatarRarity.common,
      icon: Icons.diamond,
      color1: Color(0xFFFFD700),
      color2: Color(0xFFDAA520),
      description: 'Brillo minimalista',
      unlockHint: 'Disponible en tienda',
    ),

    // ── RARE ─────────────────────────────────────────────────────────────
    AvatarDef(
      id: 'element_fire',
      name: 'Llama',
      gemCost: 250,
      rarity: AvatarRarity.rare,
      icon: Icons.local_fire_department,
      color1: Color(0xFFFF4500),
      color2: Color(0xFFFF6347),
      description: 'Fuego interior ardiente',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'element_frost',
      name: 'Escarcha',
      gemCost: 250,
      rarity: AvatarRarity.rare,
      icon: Icons.ac_unit,
      color1: Color(0xFF00BFFF),
      color2: Color(0xFF1E90FF),
      description: 'Hielo eterno',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'element_neon',
      name: 'Neón',
      gemCost: 300,
      rarity: AvatarRarity.rare,
      icon: Icons.bolt,
      color1: Color(0xFF39FF14),
      color2: Color(0xFF00FF7F),
      description: 'Energía pura electrizante',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'element_rune',
      name: 'Runa',
      gemCost: 350,
      rarity: AvatarRarity.rare,
      icon: Icons.auto_awesome,
      color1: Color(0xFF8B00FF),
      color2: Color(0xFF9400D3),
      description: 'Símbolo de poder ancestral',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'element_crystal',
      name: 'Cristal',
      gemCost: 400,
      rarity: AvatarRarity.rare,
      icon: Icons.diamond,
      color1: Color(0xFFFF69B4),
      color2: Color(0xFFFF1493),
      description: 'Gemas de poder rosa',
      unlockHint: 'Disponible en tienda',
    ),

    // ── EPIC ─────────────────────────────────────────────────────────────
    AvatarDef(
      id: 'theme_cyber',
      name: 'Cyber',
      gemCost: 600,
      rarity: AvatarRarity.epic,
      icon: Icons.memory,
      color1: Color(0xFF00D4FF),
      color2: Color(0xFFFF00FF),
      description: 'Realidad digital aumentada',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'theme_cosmic',
      name: 'Cósmico',
      gemCost: 700,
      rarity: AvatarRarity.epic,
      icon: Icons.rocket_launch,
      color1: Color(0xFF191970),
      color2: Color(0xFF4B0082),
      description: 'Explorador del espacio infinito',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'theme_glitch',
      name: 'Glitch',
      gemCost: 800,
      rarity: AvatarRarity.epic,
      icon: Icons.blur_on,
      color1: Color(0xFFFF00FF),
      color2: Color(0xFF00FFFF),
      description: 'Error en la matrix',
      unlockHint: 'Disponible en tienda',
    ),
    AvatarDef(
      id: 'theme_crown',
      name: 'Corona',
      gemCost: 900,
      rarity: AvatarRarity.epic,
      icon: Icons.emoji_events,
      color1: Color(0xFF8B4513),
      color2: Color(0xFFFFD700),
      description: 'Realeza del Sudoku',
      unlockHint: '30 victorias en campaña',
    ),

    // ── LEGENDARY ────────────────────────────────────────────────────────
    AvatarDef(
      id: 'legend_dragon',
      name: 'Dragón',
      gemCost: 1200,
      rarity: AvatarRarity.legendary,
      icon: Icons.pets,
      color1: Color(0xFFFF4500),
      color2: Color(0xFF8B0000),
      description: 'El poder del dragón milenario',
      unlockHint: 'Completa 100 niveles de campaña',
    ),
    AvatarDef(
      id: 'legend_phoenix',
      name: 'Fénix',
      gemCost: 1400,
      rarity: AvatarRarity.legendary,
      icon: Icons.whatshot,
      color1: Color(0xFFFF6347),
      color2: Color(0xFFFFD700),
      description: 'Renace de las cenizas',
      unlockHint: 'Racha de 30 días',
    ),
    AvatarDef(
      id: 'legend_eclipse',
      name: 'Eclipse',
      gemCost: 1600,
      rarity: AvatarRarity.legendary,
      icon: Icons.dark_mode,
      color1: Color(0xFF2F2F2F),
      color2: Color(0xFFFF8C00),
      description: 'La luz que emerge de la oscuridad',
      unlockHint: 'Victoria perfecta en todas las dificultades',
    ),
    AvatarDef(
      id: 'legend_void',
      name: 'Vacío',
      gemCost: 1800,
      rarity: AvatarRarity.legendary,
      icon: Icons.remove_red_eye,
      color1: Color(0xFF000000),
      color2: Color(0xFF4B0082),
      description: 'El ojo que todo lo ve',
      unlockHint: 'Completa desafío diario 7 días seguidos',
    ),

    // ── MYTHIC ───────────────────────────────────────────────────────────
    AvatarDef(
      id: 'mythic_aether',
      name: 'Aether',
      gemCost: 2500,
      rarity: AvatarRarity.mythic,
      icon: Icons.stars,
      color1: Color(0xFFE8E8FF),
      color2: Color(0xFFDDA0DD),
      description: 'Esencia etérea del universo',
      unlockHint: 'Evento especial limitado',
    ),
    AvatarDef(
      id: 'mythic_eternity',
      name: 'Eternidad',
      gemCost: 3000,
      rarity: AvatarRarity.mythic,
      icon: Icons.auto_awesome,
      color1: Color(0xFFFFD700),
      color2: Color(0xFFFF69B4),
      description: 'El infinito al alcance de tu mano',
      unlockHint: 'Logro «Maestro del Sudoku»',
    ),
  ];

  static AvatarDef? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static const String defaultId = 'geo_circle';

  static AvatarDef get defaultAvatar => all.first;
}
