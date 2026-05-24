# Heatmap + Currency Icons + Advanced Notes Fix

## 1) Heatmap Post-Game

### Problem
Heatmap (`_HeatmapSummary` in `victory_screen.dart`) only showed for normal games. Campaign used a dialog (`_showVictory`) and daily used an in-situ completed state — neither navigated to `VictoryScreen`, so heatmap was never visible for those modes.

### Fix
- **Campaign** (`campaign_game_screen.dart`): `_listenToGameOver()` now calls `context.pushReplacement('/victory', extra: 'campaign_$level')` on win instead of showing a dialog. Removed unused `_showVictory()` method and its helper methods.
- **Daily** (`daily_challenge_screen.dart`): `_setupGameOverListener()` now calls `context.pushReplacement('/victory', extra: 'daily')` on win (after marking completed + updating streak).
- **VictoryScreen** (`victory_screen.dart`): `_ActionButtons` now detects game mode from `GameSessionContext`:
  - Normal: REPLAY / SIGUIENTE / MENÚ (unchanged)
  - Campaign: REPLAY (restarts level via `/campaign-game`) / CAMPAÑA (pop back)
  - Daily: REPLAY / MENÚ (no SIGUIENTE)

All modes now show the same result flow: victory animation → XP → heatmap → stats → buttons.

### Files
| File | Change |
|------|--------|
| `campaign_game_screen.dart` | Victory routes to `/victory`, removed `_showVictory` |
| `daily_challenge_screen.dart` | Victory routes to `/victory` |
| `victory_screen.dart` | Context-aware `_ActionButtons` |

---

## 2) Currency Icons

### Problem
Inconsistent currency icons: shop used `Icons.diamond` (purple) + `Icons.water_drop` (blue), but menu and wheel used emoji strings `💎` + `🔷` with different colors.

### Fix
Created `CurrencyIconRegistry` as single source of truth:

```dart
class CurrencyIconRegistry {
  static const soulsIcon = Icons.diamond;
  static const soulsColor = Color(0xFF9B59B6);
  static const soulsLabel = 'SOULS';
  static const soulsEmoji = '💎';
  static const tokensIcon = Icons.water_drop;
  static const tokensColor = Color(0xFF3498DB);
  static const tokensLabel = 'TOKENS';
  static const tokensEmoji = '🔷';
}
```

### Files updated
| File | What changed |
|------|-------------|
| `shared/currency_icon_registry.dart` | **NEW** — registry with all currency icon constants |
| `economy/presentation/shop_screen.dart` | References registry instead of hardcoded `Icons.diamond`/`Icons.water_drop` |
| `menu/menu_screen.dart` | `_CurrencyChip` uses registry emoji + color constants |
| `wheel/domain/wheel_reward.dart` | `wheelSegments` uses `CurrencyIconRegistry.soulsEmoji`/`.tokensEmoji` |
| `onboarding/difficulty_unlock_dialog.dart` | Reward chips use registry emoji + color constants |

---

## 3) Advanced Notes Single-Consumption

### Problem
`toggleAdvancedNotes()` consumed one advanced note EVERY time the user toggled ON, even if they had already paid in the same game session. No persistence of unlock state across saves.

### Fix
Added `advancedNotesUnlockedForRun` flag to `GameState`:

- **Initial**: `false` (default in `GameState` constructor)
- **First toggle ON**: if `false`, consume 1 from wallet, set to `true`
- **Subsequent toggles**: ON/OFF freely, no consumption
- **Reset**: automatically on new game init (init, initCampaign, initDaily, restartCurrentBoard all create fresh `GameState` with default `false`)
- **Persist**: saved/restored in autosave, global save, and daily challenge storage
- **Added `_autosave()` call** in `toggleAdvancedNotes()` (was missing)

### Reset triggers
| Reset | No reset |
|-------|----------|
| Win (new game) | Toggle ON/OFF |
| Lose | Pause |
| Restart board | Save game |
| New board (SIGUIENTE) | Resume game |
| Abandon game | Exit to home |
| New daily | Reopen app |
| New campaign | Continue game |

### Files changed
| File | Change |
|------|--------|
| `game/domain/game_state.dart` | Added `advancedNotesUnlockedForRun` field + copyWith |
| `game/application/game_provider.dart` | `toggleAdvancedNotes()` checks flag before consuming; added `_autosave()` |
| `game/data/game_autosave.dart` | Save/restore `advancedNotesUnlockedForRun` |
| `game/data/save/global_saved_game.dart` | Added field + serialization |
| `game/presentation/game_screen.dart` | Restore field from global save |
| `challenge/presentation/daily_challenge_screen.dart` | Save/restore field |

### Test scenarios
- Activate → consumes 1
- Toggle 20 times → still 1 consumed
- Save → load → toggle free (no consumption)
- Restart → consumes again
- Win → new game → consumes again
- Abandon → new game → consumes again

---

## Verification
- `flutter analyze`: **0 errors, 0 warnings** from all changes
- Only pre-existing `info` lint items remain
