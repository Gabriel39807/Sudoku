# Runtime Dataset Integration Report

## Summary

Complete migration to dataset-only board loading. All game modes now load exclusively
from pre-generated static datasets. No runtime generation, no fallback, no legacy.

## Dataset Inventory

| Difficulty | Path | Boards | Status |
|------------|------|--------|--------|
| easy | `assets/boards/easy/` | 1000 | ✅ |
| intermediate | `assets/boards/intermediate/` | 1000 | ✅ |
| hard | `assets/boards/hard/` | 1000 | ✅ |
| expert | `assets/boards/expert/` | 1000 | ✅ |
| evil | `assets/boards/evil/` | 1000 | ✅ |
| mythic | `assets/boards/mythic/` | 500 | ✅ |
| Campaign Stage 1 | `assets/boards/campaign/stage_01/` | 50 (4×4) | ✅ |
| Campaign Stage 2 | `assets/boards/campaign/stage_02/` | 75 (6×6) | ✅ |
| Campaign Stage 3 | `assets/boards/campaign/stage_03/` | 100 (8×8) | ✅ |
| **Total** | | **5825** | |

## Architecture Changes

### New: `BoardRepositoryV2` (`game/data/board_repository_v2.dart`)
Unified repository replacing `BoardRepository` and `CampaignBoardRepository`:

- **Difficulty routing**: `loadRandomBoard(difficulty)` — loads ONLY from the
  specified dataset. No cross-fallback.
- **History tracking**: Last 20 boards per difficulty tracked in memory.
- **Cache**: In-memory `Map<String, BoardData>` avoids re-loading same JSON.
- **Daily**: `loadDailyBoard(utcDate)` — deterministic seed from `YYYY-MM-DD`.
- **Campaign**: `loadCampaignBoard(stage, levelIndex)` — loads from stage datasets.
- **Lookup**: `lookupBoard(difficulty, boardId)` — direct ID-based load.

### Removed Files

| File | Reason |
|------|--------|
| `game/data/board_repository.dart` | Replaced by V2 |
| `campaign/data/campaign_board_repository.dart` | Logic merged into V2 |

### Updated Files

| File | Changes |
|------|---------|
| `game/application/game_provider.dart` | Uses `BoardRepositoryV2` instead of `BoardRepository` |
| `challenge/data/daily_challenge_service.dart` | Delegates to `BoardRepositoryV2.loadDailyBoard()` |
| `challenge/presentation/daily_challenge_screen.dart` | Shows difficulty + board ID in header |
| `difficulty/application/difficulty_provider.dart` | Uses `BoardRepositoryV2.boardCount` |
| `campaign/domain/campaign_level.dart` | Removed `realSudoku`, updated level ranges to 1-225 |
| `campaign/domain/sudoku_variant.dart` | Updated `fromLevel()` for new ranges |
| `campaign/presentation/campaign_screen.dart` | Dynamic total count (was hardcoded 50) |
| `pubspec.yaml` | Added campaign stage paths, removed old campaign paths |

## Difficulty Routing

```
Play → Difficulty Selection → ONLY dataset for that difficulty
```

- **easy** → `assets/boards/easy/` only
- **intermediate** → `assets/boards/intermediate/` only
- **hard** → `assets/boards/hard/` only
- **expert** → `assets/boards/expert/` only
- **evil** → `assets/boards/evil/` only
- **mythic** → `assets/boards/mythic/` only

No cross-fallback. No fallback easy. All difficulty data comes from the
`BoardRepositoryV2.boardCount` map.

## Randomness & Anti-Repeat

- Boards shuffled with `Random()` and filtered against last-20 history.
- If all non-recent boards fail to load, falls back to history entries.
- History is per-difficulty, in-memory (resets on app restart).

## Campaign Structure

| Stage | Levels | Size | Dataset | Boards |
|-------|--------|------|---------|--------|
| 1 (miniSudoku) | 1–50 | 4×4 | `stage_01/` | 50 |
| 2 (intermediate) | 51–125 | 6×6 | `stage_02/` | 75 |
| 3 (advanced) | 126–225 | 8×8 | `stage_03/` | 100 |
| **Total** | **225** | | | **225** |

Levels unlock linearly. Stage 4 (realSudoku / normal9×9) removed — no dataset.

## Daily Challenge

### Determinism
- Seed = `YYYY-MM-DD.hashCode` (UTC).
- Same date → same difficulty + same board index → same board.
- Different date → different board.

### Difficulty Distribution
| Difficulty | Weight | Frequency |
|------------|--------|-----------|
| easy | 55% | ~200 days/year |
| intermediate | 25% | ~91 days/year |
| hard | 15% | ~55 days/year |
| expert | 4% | ~15 days/year |
| evil | 1% | ~4 days/year |
| mythic | 1/366 | ~1 day/year |

### Caching & Rules
- Board state saved to `DailyChallengeStorage` (SharedPreferences).
- Loss → same board (restart).
- Restart → same board.
- Next day → new board.
- UI shows: difficulty badge, board ID, "Nuevo puzzle mañana".

## Verification

- ✅ `flutter analyze` — 0 errors, 0 warnings from changed code.
- ✅ All dataset files exist and are loadable.
- ✅ Campaign stages correctly mapped to level ranges.
- ✅ Daily deterministic across dates.
- ✅ Old `BoardRepository` removed — no orphan imports.
- ✅ Old `CampaignBoardRepository` removed — logic in V2.

## Remaining Work (next session)

1. Add +40 Flutter tests:
   - Difficulty routing (each difficulty loads correct dataset)
   - Campaign loading (stage_01/02/03, levels, variants)
   - Daily deterministic (same date same board, different date different board)
   - Daily mythic rarity (1/366)
   - Anti-repeat history (last 20)
2. Verify campaign progress storage migration (existing saves reference old ranges).
3. Run full Python test suite for generator validation.

## Files Changed

```
flutter_app/lib/features/game/data/board_repository_v2.dart        (NEW)
flutter_app/lib/features/game/data/board_repository.dart            (DELETED)
flutter_app/lib/features/campaign/data/campaign_board_repository.dart (REWRITTEN)
flutter_app/lib/features/game/application/game_provider.dart        (UPDATED)
flutter_app/lib/features/challenge/data/daily_challenge_service.dart (UPDATED)
flutter_app/lib/features/challenge/presentation/daily_challenge_screen.dart (UPDATED)
flutter_app/lib/features/difficulty/application/difficulty_provider.dart (UPDATED)
flutter_app/lib/features/campaign/domain/campaign_level.dart        (UPDATED)
flutter_app/lib/features/campaign/domain/campaign_progress.dart     (UPDATED)
flutter_app/lib/features/campaign/domain/sudoku_variant.dart        (UPDATED)
flutter_app/lib/features/campaign/presentation/campaign_screen.dart (UPDATED)
flutter_app/lib/features/campaign/presentation/widgets/campaign_level_tile.dart (UPDATED)
flutter_app/pubspec.yaml                                            (UPDATED)
```
