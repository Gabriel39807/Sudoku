class Wallet {
  static const maxHints = 20;
  static const maxAdvancedNotes = 10;

  final int gems;
  final int tokens;
  final int hintConsumables;
  final int advancedNoteConsumables;
  final List<String> ownedPremiumCosmetics;

  const Wallet({
    this.gems = 0,
    this.tokens = 0,
    this.hintConsumables = 0,
    this.advancedNoteConsumables = 0,
    this.ownedPremiumCosmetics = const [],
  });

  Wallet copyWith({
    int? gems,
    int? tokens,
    int? hintConsumables,
    int? advancedNoteConsumables,
    List<String>? ownedPremiumCosmetics,
  }) =>
      Wallet(
        gems: gems ?? this.gems,
        tokens: tokens ?? this.tokens,
        hintConsumables: hintConsumables ?? this.hintConsumables,
        advancedNoteConsumables: advancedNoteConsumables ?? this.advancedNoteConsumables,
        ownedPremiumCosmetics: ownedPremiumCosmetics ?? this.ownedPremiumCosmetics,
      );

  Map<String, dynamic> toJson() => {
        'souls': gems,
        'tokens': tokens,
        'hintConsumables': hintConsumables,
        'advancedNoteConsumables': advancedNoteConsumables,
        'ownedPremiumCosmetics': ownedPremiumCosmetics,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        gems: json['souls'] as int? ?? 0,
        tokens: json['tokens'] as int? ?? 0,
        hintConsumables: json['hintConsumables'] as int? ?? 0,
        advancedNoteConsumables: json['advancedNoteConsumables'] as int? ?? 0,
        ownedPremiumCosmetics: (json['ownedPremiumCosmetics'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
