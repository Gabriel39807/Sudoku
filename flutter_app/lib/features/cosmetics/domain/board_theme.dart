import 'package:flutter/material.dart';

class BoardTheme {
  final String id;
  final String name;
  final String backgroundPath;
  final String frameId;
  final bool locked;
  final String rarity;

  // FUTURE: coins, gems, unlockCost, shopCategory

  const BoardTheme({
    required this.id,
    required this.name,
    required this.backgroundPath,
    required this.frameId,
    this.locked = false,
    this.rarity = 'common',
  });

  ImageProvider get imageProvider => AssetImage(backgroundPath);

  BoardTheme copyWith({
    String? id,
    String? name,
    String? backgroundPath,
    String? frameId,
    bool? locked,
    String? rarity,
  }) {
    return BoardTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      frameId: frameId ?? this.frameId,
      locked: locked ?? this.locked,
      rarity: rarity ?? this.rarity,
    );
  }

  static final List<BoardTheme> defaults = [
    BoardTheme(
      id: 'default',
      name: 'Default',
      backgroundPath: 'assets/cosmetics/backgrounds/default_board.webp',
      frameId: 'default',
      rarity: 'common',
    ),
    BoardTheme(
      id: 'night',
      name: 'Night',
      backgroundPath: 'assets/cosmetics/backgrounds/night_board.webp',
      frameId: 'shadow',
      rarity: 'uncommon',
    ),
    BoardTheme(
      id: 'crystal',
      name: 'Crystal',
      backgroundPath: 'assets/cosmetics/backgrounds/crystal_board.webp',
      frameId: 'crystal',
      rarity: 'rare',
    ),
  ];
}
