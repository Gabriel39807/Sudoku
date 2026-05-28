enum AssistMode { classic, casual, expert, extreme }

class SettingsModel {
  final bool vibrateOnError;
  final bool highlightRegion;
  final bool highlightSameNumbers;
  final bool boardAnimations;
  final bool showAutoComplete;
  final bool autoCandidates;
  final bool intenseSubgrids;
  final AssistMode assistMode;

  const SettingsModel({
    this.vibrateOnError = true,
    this.highlightRegion = true,
    this.highlightSameNumbers = true,
    this.boardAnimations = true,
    this.showAutoComplete = true,
    this.autoCandidates = true,
    this.intenseSubgrids = false,
    this.assistMode = AssistMode.classic,
  });

  SettingsModel copyWith({
    bool? vibrateOnError,
    bool? highlightRegion,
    bool? highlightSameNumbers,
    bool? boardAnimations,
    bool? showAutoComplete,
    bool? autoCandidates,
    bool? intenseSubgrids,
    AssistMode? assistMode,
  }) {
    return SettingsModel(
      vibrateOnError: vibrateOnError ?? this.vibrateOnError,
      highlightRegion: highlightRegion ?? this.highlightRegion,
      highlightSameNumbers: highlightSameNumbers ?? this.highlightSameNumbers,
      boardAnimations: boardAnimations ?? this.boardAnimations,
      showAutoComplete: showAutoComplete ?? this.showAutoComplete,
      autoCandidates: autoCandidates ?? this.autoCandidates,
      intenseSubgrids: intenseSubgrids ?? this.intenseSubgrids,
      assistMode: assistMode ?? this.assistMode,
    );
  }
}
