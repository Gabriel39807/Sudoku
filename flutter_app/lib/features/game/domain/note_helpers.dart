/// Helper functions for note management.
class NoteHelpers {
  /// Remove [number] from all notes in the same row, column, and block as [idx].
  /// Returns a new notes map with the candidates removed.
  static Map<int, Set<int>> eliminateNumber(
    Map<int, Set<int>> notes,
    int idx,
    int number,
  ) {
    final row = idx ~/ 9;
    final col = idx % 9;
    final br = row ~/ 3;
    final bc = col ~/ 3;

    final affected = <int>{};

    // Row
    for (var c = 0; c < 9; c++) {
      affected.add(row * 9 + c);
    }
    // Column
    for (var r = 0; r < 9; r++) {
      affected.add(r * 9 + col);
    }
    // Block
    for (var dr = 0; dr < 3; dr++) {
      for (var dc = 0; dc < 3; dc++) {
        affected.add((br * 3 + dr) * 9 + (bc * 3 + dc));
      }
    }

    final result = <int, Set<int>>{};
    for (final e in notes.entries) {
      if (affected.contains(e.key) && e.value.contains(number)) {
        final updated = Set<int>.from(e.value)..remove(number);
        if (updated.isNotEmpty) {
          result[e.key] = updated;
        }
      } else {
        result[e.key] = Set<int>.from(e.value);
      }
    }
    return result;
  }

  /// Compute valid candidates for an empty cell based on current board state.
  static Set<int> candidatesForCell(
    List<int> board,
    List<int> solution,
    int idx,
  ) {
    if (board[idx] != 0) return {};
    final row = idx ~/ 9;
    final col = idx % 9;
    final br = row ~/ 3;
    final bc = col ~/ 3;

    final used = <int>{};
    for (var c = 0; c < 9; c++) {
      final v = board[row * 9 + c];
      if (v != 0) used.add(v);
    }
    for (var r = 0; r < 9; r++) {
      final v = board[r * 9 + col];
      if (v != 0) used.add(v);
    }
    for (var dr = 0; dr < 3; dr++) {
      for (var dc = 0; dc < 3; dc++) {
        final v = board[(br * 3 + dr) * 9 + (bc * 3 + dc)];
        if (v != 0) used.add(v);
      }
    }
    final candidates = <int>{};
    for (var n = 1; n <= 9; n++) {
      if (!used.contains(n)) candidates.add(n);
    }
    return candidates;
  }

  /// Recompute all candidates for all empty cells.
  static Map<int, Set<int>> computeAllCandidates(
    List<int> board,
    List<int> solution,
  ) {
    final result = <int, Set<int>>{};
    for (var i = 0; i < 81; i++) {
      if (board[i] == 0) {
        final candidates = candidatesForCell(board, solution, i);
        if (candidates.isNotEmpty) {
          result[i] = candidates;
        }
      }
    }
    return result;
  }

  /// Check if a note at [idx] with value [number] is still valid.
  static bool isNoteValid(List<int> board, int idx, int number) {
    if (board[idx] != 0) return false;
    final row = idx ~/ 9;
    final col = idx % 9;
    final br = row ~/ 3;
    final bc = col ~/ 3;

    for (var c = 0; c < 9; c++) {
      if (board[row * 9 + c] == number) return false;
    }
    for (var r = 0; r < 9; r++) {
      if (board[r * 9 + col] == number) return false;
    }
    for (var dr = 0; dr < 3; dr++) {
      for (var dc = 0; dc < 3; dc++) {
        if (board[(br * 3 + dr) * 9 + (bc * 3 + dc)] == number) return false;
      }
    }
    return true;
  }

  /// Find all notes that are invalid given the current board.
  static Map<int, Set<int>> findConflicts(
    Map<int, Set<int>> notes,
    List<int> board,
  ) {
    final conflicts = <int, Set<int>>{};
    for (final e in notes.entries) {
      for (final n in e.value) {
        if (!isNoteValid(board, e.key, n)) {
          conflicts.putIfAbsent(e.key, () => <int>{}).add(n);
        }
      }
    }
    return conflicts;
  }

  /// Update notes after placing [number] at [idx]: remove from house + optional recompute.
  static Map<int, Set<int>> afterNumberPlacement(
    Map<int, Set<int>> notes,
    int idx,
    int number,
    bool autoCandidates,
    List<int> board,
    List<int> solution,
  ) {
    var updated = eliminateNumber(notes, idx, number);
    if (autoCandidates) {
      // Recompute candidates for cells affected by this placement
      final row = idx ~/ 9;
      final col = idx % 9;
      final br = row ~/ 3;
      final bc = col ~/ 3;

      final affected = <int>{};
      for (var c = 0; c < 9; c++) { affected.add(row * 9 + c); }
      for (var r = 0; r < 9; r++) { affected.add(r * 9 + col); }
      for (var dr = 0; dr < 3; dr++) {
        for (var dc = 0; dc < 3; dc++) {
          affected.add((br * 3 + dr) * 9 + (bc * 3 + dc));
        }
      }

      for (final i in affected) {
        if (board[i] == 0) {
          final candidates = candidatesForCell(board, solution, i);
          if (candidates.isNotEmpty) {
            updated[i] = candidates;
          } else {
            updated.remove(i);
          }
        }
      }
    }
    return updated;
  }
}
