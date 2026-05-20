# Evil Fix Report

## Scope

- Worked only in `flutter_app/assets/boards/evil`.
- Did not touch easy/intermediate/hard/expert/mythic.
- Did not touch Flutter UI or build outputs.

## Summary

| Metric | Value |
|---|---:|
| Legacy repaired | 100 |
| Legacy intact | 0 |
| New generated | 400 |
| Rejected | 0 |
| Duplicate hashes avoided | 0 |
| Symmetry/rotation duplicates avoided | 0 |
| XY-Wing count | 500 |
| Score average | 40 |
| Steps average | 5 |
| Evil total | 500 |
| Evil valid | 500 |
| Evil invalid | 0 |
| Exact duplicate hashes | 0 |
| Rotation/reflection duplicates | 0 |

## Legacy reparados

evil_0001, evil_0002, evil_0003, evil_0004, evil_0005, evil_0006, evil_0007, evil_0008, evil_0009, evil_0010, evil_0011, evil_0012, evil_0013, evil_0014, evil_0015, evil_0016, evil_0017, evil_0018, evil_0019, evil_0020, evil_0021, evil_0022, evil_0023, evil_0024, evil_0025, evil_0026, evil_0027, evil_0028, evil_0029, evil_0030, evil_0031, evil_0032, evil_0033, evil_0034, evil_0035, evil_0036, evil_0037, evil_0038, evil_0039, evil_0040, evil_0041, evil_0042, evil_0043, evil_0044, evil_0045, evil_0046, evil_0047, evil_0048, evil_0049, evil_0050, evil_0051, evil_0052, evil_0053, evil_0054, evil_0055, evil_0056, evil_0057, evil_0058, evil_0059, evil_0060, evil_0061, evil_0062, evil_0063, evil_0064, evil_0065, evil_0066, evil_0067, evil_0068, evil_0069, evil_0070, evil_0071, evil_0072, evil_0073, evil_0074, evil_0075, evil_0076, evil_0077, evil_0078, evil_0079, evil_0080, evil_0081, evil_0082, evil_0083, evil_0084, evil_0085, evil_0086, evil_0087, evil_0088, evil_0089, evil_0090, evil_0091, evil_0092, evil_0093, evil_0094, evil_0095, evil_0096, evil_0097, evil_0098, evil_0099, evil_0100

## Legacy intactos

(ninguno)

## Técnicas usadas

- `hidden_single`: 500
- `naked_pair`: 500
- `naked_single`: 500
- `swordfish`: 500
- `xywing`: 500

## Validation rules

- `xywing` required.
- `forcing_chain` forbidden.
- Classification by real techniques via `human_solver.py` and `classify_by_techniques.py`.
- Backtracking used only by validator for uniqueness, not for classification.
- Exact hash and rotation/reflection canonical duplicates blocked.
