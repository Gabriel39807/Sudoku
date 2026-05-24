# Easy Dataset Report
**1000 boards** — generated for Campaign Free Play

## Summary

| Metric | Value |
|--------|-------|
| Total boards | 1000 |
| Avg clues | 62.2 |
| Clue range | 60-65 |
| Avg fill | 76.9% |
| Symmetry | 180° rotational |
| Generation time | 566.4s (9.4 min) |
| Avg seconds/board | 0.57s |

## Tramo Distribution

| Tramo | Boards | Clues | Techniques |
|-------|--------|-------|------------|
| 1–250 | 250 | 65 | LastBlank, FullHouse, NakedSingle |
| 251–500 | 250 | 63 | + HiddenSingle |
| 501–750 | 250 | 61 | + PointingPair, PointingTriple |
| 751–1000 | 250 | 60 | + BoxLineReduction |

## Tier Distribution

| Tier | Boards |
|------|--------|
| 1 (Basic) | 500 |
| 2 (Intersections) | 500 |

## Technique Usage

| Technique | Boards that require it |
|-----------|----------------------|
| BoxLineReduction | 250 |
| FullHouse | 1000 |
| HiddenSingle | 750 |
| LastBlank | 1000 |
| NakedSingle | 1000 |
| PointingPair | 500 |
| PointingTriple | 500 |

## Forbidden Techniques (NOT present)

Naked Pair, Hidden Pair, Naked Triple, Hidden Triple, Naked Quad, Hidden Quad,
X-Wing, Swordfish, Jellyfish, XY-Wing, XYZ-Wing, Wings (W/M/S/L/H),
Unique Rectangle, BUG, Simple Coloring, X-Cycle, Remote Pairs, XY-Chain,
AIC, ALS, Finned Fish, Empty Rectangle, Sue de Coq, Pattern Overlay,
Forcing Chains, Nishio, all exotic fish, all chains.

## Audit Results

| Check | Result |
|-------|--------|
| Unique puzzle hashes | 1000/1000 |
| Hash integrity | OK |
| Difficulty field ("easy") | 1000/1000 |
| ID matches filename | 1000/1000 |
| Puzzle length 81 | 1000/1000 |
| Rotational symmetry | 1000/1000 |
| Duplicates (hash) | 0 |
| Multi-solution | 0 |
| Wrong metadata | 0 |

## Validation

- [OK] All 1000 boards have unique solutions
- [OK] All 1000 boards are solvable with their tramo's allowed techniques
- [OK] All 1000 boards have `difficulty: "easy"` for Flutter route validation
- [OK] All 1000 boards have rotational symmetry
- [OK] Board IDs match filenames (easy_0001...easy_1000)

## JSON Format

```json
{{
  "id": "easy_0001",
  "puzzle": "81-char string",
  "solution": "81-char string",
  "difficulty": "easy",
  "clues": 65,
  "techniques": ["LastBlank", "FullHouse", "NakedSingle"],
  "hash": "sha256 (16 chars)",
  "checksum": "...",
  "human_score": 1,
  "tier_max": 1,
  "visual_score": 0.802,
  "symmetry": "rotational",
  "tramo": 1,
  "level_index": 1,
  "estimated_time_minutes": 2
}}
```

## Flutter Integration

- `_boardCount['easy']` updated from 100 → 1000 in `board_repository.dart`
- `_boardTotalCount['easy']` updated from 100 → 1000 in `difficulty_provider.dart`
- Asset path: `assets/boards/easy/easy_XXXX.json`
- Difficulty field in JSON enables `_isValidBoard` check

## Future Work

- Rebuild intermediate/hard/expert/evil/mythic datasets (currently no boards exist)
- Add Dart tests for board repository loading
- Monitor generation cache hit rate in production
