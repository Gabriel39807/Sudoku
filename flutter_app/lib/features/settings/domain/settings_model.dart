class SettingsModel {
  final bool vibrateOnError;
  final bool highlightRegion;
  final bool highlightSameNumbers;
  final bool boardAnimations;
  final bool showAutoComplete;

  const SettingsModel({
    this.vibrateOnError = true,
    this.highlightRegion = true,
    this.highlightSameNumbers = true,
    this.boardAnimations = true,
    this.showAutoComplete = true,
  });

  SettingsModel copyWith({
    bool? vibrateOnError,
    bool? highlightRegion,
    bool? highlightSameNumbers,
    bool? boardAnimations,
    bool? showAutoComplete,
  }) {
    return SettingsModel(
      vibrateOnError: vibrateOnError ?? this.vibrateOnError,
      highlightRegion: highlightRegion ?? this.highlightRegion,
      highlightSameNumbers: highlightSameNumbers ?? this.highlightSameNumbers,
      boardAnimations: boardAnimations ?? this.boardAnimations,
      showAutoComplete: showAutoComplete ?? this.showAutoComplete,
    );
  }
}
