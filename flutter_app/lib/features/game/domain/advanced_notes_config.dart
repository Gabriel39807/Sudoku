/// Configuration for advanced notes system.
/// Prepared for future economy integration — no shop yet.
class AdvancedNotesConfig {
  final bool enabled;
  final int uses;
  final int maxUses;
  final String source; // 'free', 'event', 'reward', 'shop'

  const AdvancedNotesConfig({
    this.enabled = false,
    this.uses = 0,
    this.maxUses = 999,
    this.source = 'free',
  });

  AdvancedNotesConfig copyWith({
    bool? enabled,
    int? uses,
    int? maxUses,
    String? source,
  }) =>
      AdvancedNotesConfig(
        enabled: enabled ?? this.enabled,
        uses: uses ?? this.uses,
        maxUses: maxUses ?? this.maxUses,
        source: source ?? this.source,
      );
}
