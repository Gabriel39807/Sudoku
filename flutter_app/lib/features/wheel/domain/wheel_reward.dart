import 'dart:math' as dart_math;
import 'dart:ui' show Color;
import '../../../ui/currency/currency_assets.dart';
import '../../../ui/currency/currency_type.dart';

/// Spin types: free (daily), ad (watch), token (buy with tokens), premium (future IAP).
enum SpinType { free, ad, token, premium }

enum RewardRarity { common, medium, rare, jackpot }

class WheelReward {
  final String id;
  final String icon;
  final String label;
  final int amount;
  final RewardRarity rarity;

  const WheelReward({
    required this.id,
    required this.icon,
    required this.label,
    required this.amount,
    required this.rarity,
  });

  String get displayText => '$icon $amount';

  bool get isCurrency => id.startsWith('soul') || id.startsWith('token');
  bool get isEmpty => id == 'empty';
  bool get isAdvancedNotes => id.startsWith('advanced_notes');
  bool get isHint => id.startsWith('hint');
  bool get isFreeSpin => id == 'free_spin';
  bool get isX2Reward => id == 'x2_reward';
  bool get isJackpot => id == 'jackpot';
  bool get isSuperReward => id.startsWith('super_reward');
  bool get isLegendaryReward => id.startsWith('legendary_reward');

  CurrencyType? get currencyType {
    if (id.startsWith('soul')) return CurrencyType.souls;
    if (id.startsWith('token')) return CurrencyType.tokens;
    return null;
  }
}

class WheelSegment {
  final WheelReward reward;
  final double weight;
  final Color color;

  const WheelSegment({
    required this.reward,
    required this.weight,
    required this.color,
  });
}

final wheelSegments = [
  WheelSegment(
    reward: WheelReward(id: 'token_1', icon: CurrencyAssets.emojiFor(CurrencyType.tokens), label: 'Tokens', amount: 1, rarity: RewardRarity.common),
    weight: 14,
    color: const Color(0xFF42A5F5),
  ),
  WheelSegment(
    reward: WheelReward(id: 'token_3', icon: CurrencyAssets.emojiFor(CurrencyType.tokens), label: 'Tokens', amount: 3, rarity: RewardRarity.common),
    weight: 12,
    color: const Color(0xFF2196F3),
  ),
  WheelSegment(
    reward: WheelReward(id: 'token_5', icon: CurrencyAssets.emojiFor(CurrencyType.tokens), label: 'Tokens', amount: 5, rarity: RewardRarity.medium),
    weight: 8,
    color: const Color(0xFF26A69A),
  ),
  WheelSegment(
    reward: WheelReward(id: 'token_10', icon: CurrencyAssets.emojiFor(CurrencyType.tokens), label: 'Tokens', amount: 10, rarity: RewardRarity.rare),
    weight: 3,
    color: const Color(0xFF7E57C2),
  ),
  WheelSegment(
    reward: WheelReward(id: 'token_15', icon: CurrencyAssets.emojiFor(CurrencyType.tokens), label: 'Tokens', amount: 15, rarity: RewardRarity.rare),
    weight: 2,
    color: const Color(0xFF4A148C),
  ),
  WheelSegment(
    reward: WheelReward(id: 'soul_1', icon: CurrencyAssets.emojiFor(CurrencyType.souls), label: 'Souls', amount: 1, rarity: RewardRarity.common),
    weight: 14,
    color: const Color(0xFF66BB6A),
  ),
  WheelSegment(
    reward: WheelReward(id: 'soul_3', icon: CurrencyAssets.emojiFor(CurrencyType.souls), label: 'Souls', amount: 3, rarity: RewardRarity.common),
    weight: 12,
    color: const Color(0xFF9CCC65),
  ),
  WheelSegment(
    reward: WheelReward(id: 'soul_5', icon: CurrencyAssets.emojiFor(CurrencyType.souls), label: 'Souls', amount: 5, rarity: RewardRarity.medium),
    weight: 8,
    color: const Color(0xFFFF7043),
  ),
  WheelSegment(
    reward: WheelReward(id: 'soul_8', icon: CurrencyAssets.emojiFor(CurrencyType.souls), label: 'Souls', amount: 8, rarity: RewardRarity.medium),
    weight: 4,
    color: const Color(0xFFEF5350),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'hint_1', icon: '\u{1F4A1}', label: 'Hint', amount: 1, rarity: RewardRarity.common),
    weight: 12,
    color: const Color(0xFF26C6DA),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'hint_2', icon: '\u{1F4A1}', label: 'Hints', amount: 2, rarity: RewardRarity.medium),
    weight: 7,
    color: const Color(0xFF00BCD4),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'hint_3', icon: '\u{1F4A1}', label: 'Hints', amount: 3, rarity: RewardRarity.rare),
    weight: 3,
    color: const Color(0xFF0097A7),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'advanced_notes_1', icon: '\u{270F}\u{FE0F}', label: 'Advanced Notes', amount: 1, rarity: RewardRarity.medium),
    weight: 5,
    color: const Color(0xFFEC407A),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'advanced_notes_2', icon: '\u{270F}\u{FE0F}', label: 'Advanced Notes', amount: 2, rarity: RewardRarity.rare),
    weight: 2,
    color: const Color(0xFFD81B60),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'x2_reward', icon: '\u{1F3C6}', label: 'x2 Reward', amount: 1, rarity: RewardRarity.rare),
    weight: 3,
    color: const Color(0xFFFFD700),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'free_spin', icon: '\u{1F504}', label: 'Free Spin', amount: 1, rarity: RewardRarity.medium),
    weight: 4,
    color: const Color(0xFFFFA726),
  ),
  WheelSegment(
    reward: const WheelReward(id: 'empty', icon: '\u{274C}', label: 'Try Again', amount: 0, rarity: RewardRarity.common),
    weight: 17,
    color: const Color(0xFF757575),
  ),
];

double get totalWeight => wheelSegments.fold<num>(0, (sum, s) => sum + s.weight).toDouble();

WheelReward pickWeightedReward() {
  final rng = dart_math.Random();
  final roll = rng.nextDouble() * totalWeight;
  var cumulative = 0.0;
  for (final segment in wheelSegments) {
    cumulative += segment.weight;
    if (roll < cumulative) return segment.reward;
  }
  return wheelSegments.last.reward;
}

int pickWeightedIndex() {
  final rng = dart_math.Random();
  final roll = rng.nextDouble() * totalWeight;
  var cumulative = 0.0;
  for (var i = 0; i < wheelSegments.length; i++) {
    cumulative += wheelSegments[i].weight;
    if (roll < cumulative) return i;
  }
  return wheelSegments.length - 1;
}
