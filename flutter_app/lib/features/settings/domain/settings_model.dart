enum AssistMode { classic, casual, expert, extreme }

class SettingsModel {
  final bool vibrateOnError;
  final bool highlightRegion;
  final bool highlightSameNumbers;
  final bool boardAnimations;
  final bool showAutoComplete;
  final bool autoCandidates;
  final AssistMode assistMode;

  const SettingsModel({
    this.vibrateOnError = true,
    this.highlightRegion = true,
    this.highlightSameNumbers = true,
    this.boardAnimations = true,
    this.showAutoComplete = true,
    this.autoCandidates = true,
    this.assistMode = AssistMode.classic,
  });

  SettingsModel copyWith({
    bool? vibrateOnError,
    bool? highlightRegion,
    bool? highlightSameNumbers,
    bool? boardAnimations,
    bool? showAutoComplete,
    bool? autoCandidates,
    AssistMode? assistMode,
  }) {
    return SettingsModel(
      vibrateOnError: vibrateOnError ?? this.vibrateOnError,
      highlightRegion: highlightRegion ?? this.highlightRegion,
      highlightSameNumbers: highlightSameNumbers ?? this.highlightSameNumbers,
      boardAnimations: boardAnimations ?? this.boardAnimations,
      showAutoComplete: showAutoComplete ?? this.showAutoComplete,
      autoCandidates: autoCandidates ?? this.autoCandidates,
      assistMode: assistMode ?? this.assistMode,
    );
  }
}
