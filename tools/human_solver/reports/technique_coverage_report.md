# Technique Coverage Report

**Generated:** automated audit  
**Status:** 73 classes on disk, 73 registered, 0 orphans

---

## Summary

| Metric | Count |
|--------|-------|
| Total classes on disk | 73 |
| Registered (in `__all__`) | 73 |
| Orphans (on disk, not in `__all__`) | 0 |
| **Implemented** (apply() has logic, used by pipeline) | **43** |
| **Experimental** (status=experimental, skipped by pipeline) | **30** |
| Stubs (marked implemented but apply() returns None) | **3** |
| Planned | 0 |
| Deprecated | 0 |

---

## Tier 1 — Basic (4/4 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `last_blank_cell` | Last Blank Cell | 1.0 | ✅ implemented | has logic |
| `full_house` | Full House | 1.0 | ✅ implemented | has logic |
| `naked_single` | Naked Single | 1.5 | ✅ implemented | has logic |
| `hidden_single` | Hidden Single | 2.0 | ✅ implemented | has logic |

## Tier 2 — Intersections (9/9 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `pointing_pair` | Pointing Pair | 3.0 | ✅ implemented | has logic |
| `pointing_triple` | Pointing Triple | 3.5 | ✅ implemented | has logic |
| `box_line_reduction` | Box-Line Reduction | 3.5 | ✅ implemented | has logic |
| `naked_pair` | Naked Pair | 3.0 | ✅ implemented | has logic |
| `hidden_pair` | Hidden Pair | 4.0 | ✅ implemented | has logic |
| `naked_triple` | Naked Triple | 4.5 | ✅ implemented | has logic |
| `hidden_triple` | Hidden Triple | 5.0 | ✅ implemented | has logic |
| `naked_quad` | Naked Quad | 6.0 | ✅ implemented | has logic |
| `hidden_quad` | Hidden Quad | 7.0 | ✅ implemented | has logic |

## Tier 3 — Wings & Fish (12/12 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `xwing` | X-Wing | 4.0 | ✅ implemented | has logic |
| `swordfish` | Swordfish | 6.5 | ✅ implemented | has logic |
| `jellyfish` | Jellyfish | 8.0 | ✅ implemented | has logic |
| `xywing` | XY-Wing | 5.0 | ✅ implemented | has logic |
| `xyzwing` | XYZ-Wing | 5.5 | ✅ implemented | has logic |
| `wwing` | W-Wing | 5.5 | ✅ implemented | has logic |
| `mwing` | M-Wing | 6.5 | ✅ implemented | has logic |
| `swing` | S-Wing | 6.5 | ✅ implemented | has logic |
| `lwing` | L-Wing | 7.0 | ✅ implemented | has logic |
| `hwing` | H-Wing | 7.0 | ✅ implemented | has logic |
| `wxyzwing` | WXYZ-Wing | 7.5 | ✅ implemented | has logic |
| `vwxyzwing` | VWXYZ-Wing | 8.5 | ✅ implemented | has logic |

## Tier 4 — Uniqueness (5/8 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `unique_rectangle` | Unique Rectangle | 5.0 | ✅ implemented | has logic |
| `hidden_rectangle` | Hidden Rectangle | 7.0 | ✅ implemented | has logic |
| `avoidable_rectangle` | Avoidable Rectangle | 7.5 | ✅ implemented | has logic |
| `bug` | BUG | 6.0 | ✅ implemented | has logic |
| `extended_rectangle` | Extended Rectangle | 8.5 | ⚠️ experimental | stub (return None) |
| `borescope_grid` | Borescope Grid | 9.0 | ⚠️ experimental | stub (return None) |
| `qwing` | Q-Wing | 8.5 | ⚠️ experimental | stub (return None) |
| `gurth_symmetry` | Gurth's Symmetry | 10.0 | ⚠️ experimental | stub (return None) |

## Tier 5 — Chains (5/10 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `simple_coloring` | Simple Coloring | 6.0 | ✅ implemented | has logic |
| `xcycle` | X-Cycle | 7.5 | ✅ implemented | has logic |
| `remote_pairs` | Remote Pairs | 6.5 | ✅ implemented | has logic |
| `xychain` | XY-Chain | 7.5 | ✅ implemented | has logic |
| `aic` | Alternating Inference Chain | 8.0 | ✅ implemented | has logic |
| `twinned_xychain` | Twinned XY-Chain | 8.5 | ⚠️ experimental | stub (return None) |
| `grouped_aic` | Grouped AIC | 9.0 | ⚠️ experimental | stub (return None) |
| `grouped_xcycle` | Grouped X-Cycle | 8.5 | ⚠️ experimental | stub (return None) |
| `continuous_loop` | Continuous Loop | 9.0 | ⚠️ experimental | stub (return None) |
| `medusa3d` | 3D Medusa | 9.5 | ⚠️ experimental | stub (return None) |

## Tier 6 — ALS (1/4 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `alsxz` | ALS-XZ | 8.0 | ✅ implemented | has logic |
| `alsxywing` | ALS-XY-Wing | 9.0 | ⚠️ **stub** | no logic (marked implemented) |
| `alschain` | ALS Chain | 10.0 | ⚠️ experimental | stub (return None) |
| `death_blossom` | Death Blossom | 10.0 | ⚠️ experimental | stub (return None) |

## Tier 7 — Exotic Fish (5/11 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `finned_fish` | Finned Fish | 7.0 | ✅ implemented | has logic |
| `finned_xwing` | Finned X-Wing | 7.0 | ✅ implemented | has logic (inherited) |
| `finned_swordfish` | Finned Swordfish | 7.0 | ✅ implemented | has logic (inherited) |
| `finned_jellyfish` | Finned Jellyfish | 7.0 | ✅ implemented | has logic (inherited) |
| `sashimi_fish` | Sashimi Fish | 8.0 | ⚠️ **stub** | no logic (marked implemented) |
| `multivalue_xwing` | Multivalue X-Wing | 8.5 | ⚠️ experimental | stub (return None) |
| `franken_fish` | Franken Fish | 9.0 | ⚠️ experimental | stub (return None) |
| `squidward` | Squidward | 9.5 | ⚠️ experimental | stub (return None) |
| `mutant_fish` | Mutant Fish | 9.5 | ⚠️ experimental | stub (return None) |
| `siamese_fish` | Siamese Fish | 9.5 | ⚠️ experimental | stub (return None) |
| `leviathan` | Leviathan | 10.0 | ⚠️ experimental | stub (return None) |

## Tier 8 — Extreme (7/15 implemented)

| ID | Name | Difficulty | Status | apply() |
|----|------|-----------|--------|---------|
| `empty_rectangle` | Empty Rectangle | 7.0 | ✅ implemented | has logic |
| `aligned_pair_exclusion` | Aligned Pair Exclusion | 8.0 | ⚠️ experimental | solve copy hack (clone+place) |
| `pattern_overlay` | Pattern Overlay Method | 8.0 | ⚠️ experimental | backtracking (clone+place+recurse) |
| `sue_de_coq` | Sue de Coq | 8.5 | ⚠️ **stub** | no logic (marked implemented) |
| `forcing_chains` | Forcing Chains | 9.0 | ⚠️ experimental | solve copy hack (clone+place+propagate) |
| `nishio` | Nishio | 9.0 | ⚠️ experimental | delegates to forcing_chains |
| `bowmans_bingo` | Bowman's Bingo | 9.5 | ⚠️ experimental | brute force (2-level clone+try) |
| `aligned_triple_exclusion` | Aligned Triple Exclusion | 9.0 | ⚠️ experimental | stub (return None) |
| `fireworks` | Fireworks | 9.5 | ⚠️ experimental | stub (return None) |
| `extended_sue_de_coq` | Extended Sue de Coq | 9.5 | ⚠️ experimental | stub (return None) |
| `guardians` | Guardians | 9.5 | ⚠️ experimental | stub (return None) |
| `exocet` | Exocet | 10.0 | ⚠️ experimental | stub (return None) |
| `skloop` | SK Loop | 10.0 | ⚠️ experimental | stub (return None) |
| `tridagon` | Tridagon | 10.0 | ⚠️ experimental | stub (return None) |
| `double_exocet` | Double Exocet | 10.0 | ⚠️ experimental | stub (return None) |

---

## Issues Found

### Orphans Fixed
- **FinnedXWing**, **FinnedSwordfish**, **FinnedJellyfish** — defined in `finned_fish.py` as Technique subclasses with inherited `apply()`, but NOT in any `__all__`. Now added to `fish/__init__.py` and `Pipeline._manual_register()`.

### Stubs (3 marked "implemented" but no logic)

These are registered as `status="implemented"` but their `apply()` method does nothing:

| Technique | Tier | File |
|-----------|------|------|
| `ALSXYWing` | 6 | `als/alsxywing.py` |
| `SashimiFish` | 7 | `fish/sashimi_fish.py` |
| `SueDeCoq` | 8 | `extreme/sue_de_coq.py` |

These should either be implemented properly or downgraded to `status="experimental"`.

### Solve Copy Hack — 5 techniques downgraded to experimental

The Real Implementation Audit (FASE 2) found 5 techniques using `board.clone()` + `test.place()` (solve copy hack):

| Technique | Issue | Resolution |
|-----------|-------|------------|
| `pattern_overlay` | Recursive backtracking with clone | Downgraded to experimental |
| `aligned_pair_exclusion` | Clone + place 2 values to check validity | Downgraded to experimental |
| `forcing_chains` | Clone + place + propagate singles (4 occurrences) | Downgraded to experimental |
| `nishio` | Delegates to forcing_chains | Downgraded to experimental |
| `bowmans_bingo` | 2-level nested clone + try + propagate | Downgraded to experimental |

All 5 set to `implemented=False`, `experimental=True`, `status="experimental"`. The pipeline skips them.

### Experimental (30 techniques)

30 techniques marked `status="experimental"` — 25 original stubs + 5 solve-copy-hack downgrades. All are registered but skipped by the pipeline.

### Pending Verification

- Row/col/block interactions in FinnedFish base class — covers X-Wing, Swordfish, Jellyfish fins simultaneously via `_find_finned_fish()`. Subclasses FinnedXWing/FinnedSwordfish/FinnedJellyfish inherit logic but may need dedicated apply() to specialize per-fish-type.

---

## Coverage by Tier

| Tier | Registered | Pipeline-Enabled | Stubs | Experimental | Coverage |
|------|-----------|-----------------|-------|-------------|----------|
| 1 — Basic | 4 | 4 | 0 | 0 | **100%** |
| 2 — Intersections | 9 | 9 | 0 | 0 | **100%** |
| 3 — Wings & Fish | 12 | 12 | 0 | 0 | **100%** |
| 4 — Uniqueness | 8 | 5 | 0 | 3 | **62.5%** |
| 5 — Chains | 10 | 5 | 0 | 5 | **50%** |
| 6 — ALS | 4 | 1 | 1 | 2 | **25%** |
| 7 — Exotic Fish | 11 | 5 | 1 | 5 | **45.5%** |
| 8 — Extreme | 15 | 2 | 1 | 12 | **13.3%** |
| **Total** | **73** | **43** | **3** | **27** | **58.9%** |

> **Note:** "Pipeline-Enabled" = `implemented=True` (used during `solve()`). The 5 clone+place techniques were downgraded to experimental after the Implementation Audit. 30 total experimental (3 stubs + 27 pure experimental). "Coverage" = pipeline-enabled / registered × 100.

---

## Verification

- All 73 technique classes exist on disk
- All 73 are in `__all__` of their respective package
- All 73 are discoverable by `Registry`
- All 73 are registered by `Pipeline._manual_register()`
- 0 orphans, 0 duplicate IDs, 0 circular dependencies
