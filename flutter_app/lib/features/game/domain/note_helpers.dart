import '../../../features/campaign/domain/sudoku_variant.dart';

class NoteHelpers {
  static Map<int, Set<int>> eliminateNumber(
    Map<int, Set<int>> notes,
    int idx,
    int number, {
    BoardConfig config = BoardConfig.normal9,
  }) {
    final size = config.boardSize;
    final sw = config.subgridWidth;
    final sh = config.subgridHeight;
    final row = idx ~/ size;
    final col = idx % size;
    final br = row ~/ sh;
    final bc = col ~/ sw;

    final affected = <int>{};
    for (var c = 0; c < size; c++) affected.add(row * size + c);
    for (var r = 0; r < size; r++) affected.add(r * size + col);
    for (var dr = 0; dr < sh; dr++) {
      for (var dc = 0; dc < sw; dc++) {
        affected.add((br * sh + dr) * size + (bc * sw + dc));
      }
    }

    final result = <int, Set<int>>{};
    for (final e in notes.entries) {
      if (affected.contains(e.key) && e.value.contains(number)) {
        final updated = Set<int>.from(e.value)..remove(number);
        if (updated.isNotEmpty) result[e.key] = updated;
      } else {
        result[e.key] = Set<int>.from(e.value);
      }
    }
    return result;
  }

  static Set<int> candidatesForCell(
    List<int> board,
    List<int> solution,
    int idx, {
    BoardConfig config = BoardConfig.normal9,
  }) {
    if (board[idx] != 0) return {};
    final size = config.boardSize;
    final sw = config.subgridWidth;
    final sh = config.subgridHeight;
    final row = idx ~/ size;
    final col = idx % size;
    final br = row ~/ sh;
    final bc = col ~/ sw;

    final used = <int>{};
    for (var c = 0; c < size; c++) { final v = board[row * size + c]; if (v != 0) used.add(v); }
    for (var r = 0; r < size; r++) { final v = board[r * size + col]; if (v != 0) used.add(v); }
    for (var dr = 0; dr < sh; dr++) {
      for (var dc = 0; dc < sw; dc++) {
        final v = board[(br * sh + dr) * size + (bc * sw + dc)];
        if (v != 0) used.add(v);
      }
    }
    final candidates = <int>{};
    for (var n = 1; n <= size; n++) {
      if (!used.contains(n)) candidates.add(n);
    }
    return candidates;
  }

  static Map<int, Set<int>> computeAllCandidates(
    List<int> board,
    List<int> solution, {
    BoardConfig config = BoardConfig.normal9,
  }) {
    final result = <int, Set<int>>{};
    for (var i = 0; i < config.totalCells; i++) {
      if (board[i] == 0) {
        final candidates = candidatesForCell(board, solution, i, config: config);
        if (candidates.isNotEmpty) result[i] = candidates;
      }
    }
    return result;
  }

  static bool isNoteValid(List<int> board, int idx, int number, {BoardConfig config = BoardConfig.normal9}) {
    if (board[idx] != 0) return false;
    final size = config.boardSize;
    final sw = config.subgridWidth;
    final sh = config.subgridHeight;
    final row = idx ~/ size;
    final col = idx % size;
    final br = row ~/ sh;
    final bc = col ~/ sw;

    for (var c = 0; c < size; c++) { if (board[row * size + c] == number) return false; }
    for (var r = 0; r < size; r++) { if (board[r * size + col] == number) return false; }
    for (var dr = 0; dr < sh; dr++) {
      for (var dc = 0; dc < sw; dc++) {
        if (board[(br * sh + dr) * size + (bc * sw + dc)] == number) return false;
      }
    }
    return true;
  }

  static Map<int, Set<int>> findConflicts(
    Map<int, Set<int>> notes,
    List<int> board, {
    BoardConfig config = BoardConfig.normal9,
  }) {
    final conflicts = <int, Set<int>>{};
    for (final e in notes.entries) {
      for (final n in e.value) {
        if (!isNoteValid(board, e.key, n, config: config)) {
          conflicts.putIfAbsent(e.key, () => <int>{}).add(n);
        }
      }
    }
    return conflicts;
  }

  static Map<int, Set<int>> afterNumberPlacement(
    Map<int, Set<int>> notes,
    int idx,
    int number,
    bool autoCandidates,
    List<int> board,
    List<int> solution, {
    BoardConfig config = BoardConfig.normal9,
  }) {
    var updated = eliminateNumber(notes, idx, number, config: config);
    if (autoCandidates) {
      final size = config.boardSize;
      final sw = config.subgridWidth;
      final sh = config.subgridHeight;
      final row = idx ~/ size;
      final col = idx % size;
      final br = row ~/ sh;
      final bc = col ~/ sw;

      final affected = <int>{};
      for (var c = 0; c < size; c++) affected.add(row * size + c);
      for (var r = 0; r < size; r++) affected.add(r * size + col);
      for (var dr = 0; dr < sh; dr++) {
        for (var dc = 0; dc < sw; dc++) {
          affected.add((br * sh + dr) * size + (bc * sw + dc));
        }
      }

      for (final i in affected) {
        if (board[i] == 0) {
          final candidates = candidatesForCell(board, solution, i, config: config);
          if (candidates.isNotEmpty) updated[i] = candidates;
          else updated.remove(i);
        }
      }
    }
    return updated;
  }
}
