# Expert Expansion Report

## Scope

- Dataset touched: `flutter_app/assets/boards/expert`
- Generated range: `expert_0101` → `expert_0500`
- Preserved range: `expert_0001` → `expert_0100` untouched
- Seed used for safe transformations: `expert_0002`
- Human solver: `tools/generator/human_solver.py`

## Final generation summary

| Metric | Value |
|---|---:|
| Generated | 400 |
| Rejected | 0 |
| Score average | 28 |
| Steps average | 7 |
| Clues average | 25 |
| X-Wing count | 400 |
| Swordfish count | 0 |
| Duplicates avoided | 0 |
| New invalid boards | 0 |
| New duplicate hashes | 0 |

## Batch checkpoints

- `0101-0150`: completed — generated 50, attempts 50
- `0151-0200`: completed — generated 50, attempts 50
- `0201-0250`: completed — generated 50, attempts 50
- `0251-0300`: completed — generated 50, attempts 50
- `0301-0350`: completed — generated 50, attempts 50
- `0351-0400`: completed — generated 50, attempts 50
- `0401-0450`: completed — generated 50, attempts 50
- `0451-0500`: completed — generated 50, attempts 50

## Strict acceptance rules applied to new boards

- Unique solution checked via validator.
- No puzzle/solution conflicts.
- Hash checked against global `SEEN_HASHES` built from all existing expert files.
- Classification must be `expert` from `classify_by_techniques.py`.
- Solving must complete using `human_solver.py`.
- Required at least one of: `xwing`, `swordfish`.
- Rejected forbidden techniques: `xywing`, `forcing_chain`.
- No classification backtracking was used; backtracking utilities were only used by validator for solution existence/uniqueness.

## Important audit finding

The original preserved range `expert_0001` → `expert_0100` is not fully human-solvable under the current real human solver. Initial audit found:

- Existing expert files: 100
- Existing valid expert files: 1
- Existing invalid expert files: 99

Because `expert_0001` → `expert_0100` were explicitly protected from modification, the full folder cannot truthfully report 500/500 human-solvable until those legacy boards are regenerated or fixed in a separate approved change.

## Overall expert folder after expansion

- Expert board files: 500
- Valid by current validator: 401
- Invalid by current validator: 99

See `tools/generator/expert_dataset_audit.json` for per-board ids, hash, score, steps, clues, techniques, duplicates, conflicts, classification, and validity.
