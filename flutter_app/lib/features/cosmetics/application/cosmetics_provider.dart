import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/board_theme.dart';
import '../domain/frame_skin.dart';
import '../data/cosmetics_storage.dart';

class CosmeticsState {
  final BoardTheme selectedTheme;
  final FrameSkin selectedFrame;
  final List<BoardTheme> availableThemes;
  final List<FrameSkin> availableFrames;

  CosmeticsState({
    required this.selectedTheme,
    required this.selectedFrame,
    List<BoardTheme>? availableThemes,
    List<FrameSkin>? availableFrames,
  })  : availableThemes = availableThemes ?? BoardTheme.defaults,
      availableFrames = availableFrames ?? FrameSkin.defaults;

  CosmeticsState copyWith({
    BoardTheme? selectedTheme,
    FrameSkin? selectedFrame,
    List<BoardTheme>? availableThemes,
    List<FrameSkin>? availableFrames,
  }) {
    return CosmeticsState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedFrame: selectedFrame ?? this.selectedFrame,
      availableThemes: availableThemes ?? this.availableThemes,
      availableFrames: availableFrames ?? this.availableFrames,
    );
  }
}

class CosmeticsNotifier extends Notifier<CosmeticsState> {
  final _storage = CosmeticsStorage();

  @override
  CosmeticsState build() {
    _load();
    return CosmeticsState(
      selectedTheme: BoardTheme.defaults.first,
      selectedFrame: FrameSkin.defaults.first,
    );
  }

  Future<void> _load() async {
    final themeId = await _storage.loadSelectedTheme();
    final frameId = await _storage.loadSelectedFrame();

    final theme = BoardTheme.defaults.firstWhere(
      (t) => t.id == themeId,
      orElse: () => BoardTheme.defaults.first,
    );
    final frame = FrameSkin.defaults.firstWhere(
      (f) => f.id == frameId,
      orElse: () => FrameSkin.defaults.first,
    );

    state = state.copyWith(selectedTheme: theme, selectedFrame: frame);
  }

  Future<void> selectTheme(String themeId) async {
    final theme = BoardTheme.defaults.firstWhere(
      (t) => t.id == themeId,
      orElse: () => BoardTheme.defaults.first,
    );
    state = state.copyWith(selectedTheme: theme);
    await _storage.saveSelectedTheme(themeId);
  }

  Future<void> selectFrame(String frameId) async {
    final frame = FrameSkin.defaults.firstWhere(
      (f) => f.id == frameId,
      orElse: () => FrameSkin.defaults.first,
    );
    state = state.copyWith(selectedFrame: frame);
    await _storage.saveSelectedFrame(frameId);
  }
}

final cosmeticsProvider =
    NotifierProvider<CosmeticsNotifier, CosmeticsState>(CosmeticsNotifier.new);
