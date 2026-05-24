# Board Context Isolation Fix

## Problem

When a user exits a campaign game (or daily challenge) and navigates to a normal difficulty screen (easy/intermediate/etc.), the `_initGame` guard in `game_screen.dart` incorrectly skips re-initialization because it only checks **if any session exists with `status == playing`** — not whether that session's context matches the requested mode.

### Root Cause

- `abandonGame()` in `game_provider.dart:682` did **not** clear the `GameSession` — it only canceled the timer and cleared the locked number
- `_initGame` guard at `game_screen.dart:60` returned early if `session != null && status == playing`, regardless of game mode
- Campaign and daily challenge booleans (`_isCampaign`, `_isDailyChallenge`, `_campaignLevel`) were tracked separately without a consistent context model

### Impact

Campaign board displayed as "easy", daily board displayed as "hard", etc. — incorrect board for the requested difficulty.

---

## Solution: `GameSessionContext`

Created a new model `GameSessionContext` (`game/domain/game_session_context.dart`) that encapsulates the full origin of a game session:

```dart
enum GameMode { normal, campaign, daily, savedGame }

class GameSessionContext {
  final GameMode mode;
  final String difficulty;
  final String boardId;
  final String dataset;
  final String origin;
  final String? saveSlot;
  final int? seed;
  final int? progress;
}
```

### Changes

| File | Change |
|------|--------|
| `game/domain/game_session_context.dart` | **NEW** — `GameMode` enum + `GameSessionContext` class with `copyWith` |
| `game/application/game_provider.dart` | Removed `_isDailyChallenge`, `_isCampaign` booleans; replaced with `GameSessionContext? _currentContext` + getter. Updated all `init*()` methods to set context. `abandonGame()` now clears context + resets state to `const GameState()`. `restartGame()` sets context if null. |
| `game/presentation/game_screen.dart` | `_initGame()` guard checks `notifier.currentContext.mode == GameMode.normal && ctx.difficulty == diff` before skipping init. On mismatch, calls `abandonGame()` to clear stale session. |

### Behavior per scenario

| Scenario | Before | After |
|----------|--------|-------|
| Campaign → Easy | Shows campaign board as "easy" | `abandonGame()` clears campaign session, loads fresh easy board |
| Daily → Hard | Shows daily board as "hard" | Context mismatch detected, fresh hard board loaded |
| Easy → same Easy (back/forward) | Restarts (bad UX) | Context matches, skips init — preserves progress |
| Normal game (playing) → another difficulty | Loads new | Context diff mismatch, `abandonGame` clears, fresh board |

### Verification

- `flutter analyze`: 0 errors, 0 warnings from changed code
- All pre-existing `info`-level lint warnings unchanged

### Files touched

- `flutter_app/lib/features/game/domain/game_session_context.dart` (created, 66 lines)
- `flutter_app/lib/features/game/application/game_provider.dart` (+50/-30 lines)
- `flutter_app/lib/features/game/presentation/game_screen.dart` (+6/-3 lines)
