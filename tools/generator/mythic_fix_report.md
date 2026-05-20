# Mythic Fix Report

## Scope

- Regenerated only `flutter_app/assets/boards/mythic/mythic_0001.json` → `mythic_0500.json`.
- Did not touch easy/intermediate/hard/expert/evil.
- Did not touch Flutter UI or build outputs.

## Solver fix

`tools/generator/techniques/forcing_chain.py` was rewritten as a bounded contradiction-chain technique. `human_solver.py` keeps the human order and now records forcing-chain trigger logs in the returned `logs`/`applications` data.

## Benchmark

- Attempts: 300
- Forcing-chain hits: 103
- XY-Wing hits: 29
- Avg benchmark steps: 6.02
- Avg benchmark score: 49.27

## Dataset summary

| Metric | Value |
|---|---:|
| Mythic total | 500 |
| Mythic valid | 500 |
| Mythic invalid | 0 |
| Forcing-chain count | 500 |
| XY-Wing count | 500 |
| Exact duplicates | 0 |
| Geometry duplicates | 0 |
| Score average | 57.98 |
| Steps average | 5.2 |
| Clues average | 24 |
| Rejected candidates | 0 |

## Technique counts

- `box_line_reduction`: 34
- `forcing_chain`: 500
- `hidden_single`: 500
- `naked_pair`: 56
- `naked_single`: 500
- `pointing_pair`: 500
- `swordfish`: 10
- `xywing`: 500
