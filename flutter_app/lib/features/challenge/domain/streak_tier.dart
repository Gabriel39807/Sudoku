import 'package:flutter/material.dart';

enum StreakTier {
  extinct(0, 0,
    label: 'Extinto',
    icon: '🔥',
    flameColor: Color(0xFF444444),
    glowColor: Color(0xFF333333),
    accentColor: Color(0xFF555555),
    textColor: Color(0xFF666666),
    description: 'Sin racha activa',
    reward: 'Sin bonus',
    glowIntensity: 0,
    flameScale: 0.6,
    pulseSpeed: 0,
    hasParticles: false,
    hasAura: false,
    hasSparkles: false,
  ),
  ember(1, 3,
    label: 'Ascuas',
    icon: '🔥',
    flameColor: Color(0xFFFF8C42),
    glowColor: Color(0xFFFF6B35),
    accentColor: Color(0xFFFFB066),
    textColor: Color(0xFFFFB066),
    description: 'La llama despierta',
    reward: '+5% GEMS',
    glowIntensity: 0.25,
    flameScale: 0.8,
    pulseSpeed: 0.8,
    hasParticles: false,
    hasAura: false,
    hasSparkles: false,
  ),
  blazing(4, 7,
    label: 'Ardiente',
    icon: '🔥',
    flameColor: Color(0xFFFF6B35),
    glowColor: Color(0xFFFF4500),
    accentColor: Color(0xFFFF8C42),
    textColor: Color(0xFFFF8C42),
    description: 'Fuego constante',
    reward: '+5% GEMS',
    glowIntensity: 0.45,
    flameScale: 0.9,
    pulseSpeed: 1.0,
    hasParticles: true,
    hasAura: false,
    hasSparkles: false,
  ),
  inferno(8, 14,
    label: 'Inferno',
    icon: '🔥',
    flameColor: Color(0xFFFF4500),
    glowColor: Color(0xFFD32F2F),
    accentColor: Color(0xFFFF6B35),
    textColor: Color(0xFFFF6B35),
    description: 'Llamas intensas',
    reward: '+10% GEMS',
    glowIntensity: 0.6,
    flameScale: 1.0,
    pulseSpeed: 1.2,
    hasParticles: true,
    hasAura: false,
    hasSparkles: false,
  ),
  legendary(15, 29,
    label: 'Legendario',
    icon: '🔥',
    flameColor: Color(0xFFFFD700),
    glowColor: Color(0xFFFF8C00),
    accentColor: Color(0xFFFFD700),
    textColor: Color(0xFFFFD700),
    description: 'Fuego legendario',
    reward: '+15% GEMS',
    glowIntensity: 0.8,
    flameScale: 1.15,
    pulseSpeed: 1.4,
    hasParticles: true,
    hasAura: true,
    hasSparkles: false,
  ),
  mythic(30, null,
    label: 'Mítico',
    icon: '🔥',
    flameColor: Color(0xFFBB86FC),
    glowColor: Color(0xFF9C4DFF),
    accentColor: Color(0xFFE040FB),
    textColor: Color(0xFFE040FB),
    description: 'Leyenda viviente',
    reward: '+20% GEMS + giro extra',
    glowIntensity: 1.0,
    flameScale: 1.3,
    pulseSpeed: 1.6,
    hasParticles: true,
    hasAura: true,
    hasSparkles: true,
  );

  final int min;
  final int? max;
  final String label;
  final String icon;
  final Color flameColor;
  final Color glowColor;
  final Color accentColor;
  final Color textColor;
  final String description;
  final String reward;
  final double glowIntensity;
  final double flameScale;
  final double pulseSpeed;
  final bool hasParticles;
  final bool hasAura;
  final bool hasSparkles;

  const StreakTier(this.min, this.max, {
    required this.label,
    required this.icon,
    required this.flameColor,
    required this.glowColor,
    required this.accentColor,
    required this.textColor,
    required this.description,
    required this.reward,
    required this.glowIntensity,
    required this.flameScale,
    required this.pulseSpeed,
    required this.hasParticles,
    required this.hasAura,
    required this.hasSparkles,
  });

  bool contains(int streak) => streak >= min && (max == null || streak <= max!);

  static StreakTier forStreak(int streak) {
    for (final tier in values) {
      if (tier.contains(streak)) return tier;
    }
    return extinct;
  }

  static List<StreakTier> allUntil(int streak) {
    return values.where((t) => t.min <= streak).toList();
  }

  StreakTier? get next {
    final i = index + 1;
    return i < values.length ? values[i] : null;
  }

  int get daysUntilNext {
    final n = next;
    if (n == null) return 0;
    return n.min - min;
  }
}
