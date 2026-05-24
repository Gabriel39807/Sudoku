# Real Implementation Audit

**Goal:** Verify that NO technique uses backtracking, brute force, hidden solver, solve copy hack, or guessing.

---

## Verdict

| Metric | Count |
|--------|-------|
| **Total audited** | **48** (implemented techniques with logic) |
| **PASSED** | **43** (pure candidate analysis) |
| **FAILED** | **5** (use `board.clone()` + `test.place()` — solve copy hack) |

**100% backtracking-free?** ❌ — 5 techniques fail.

---

## PASSED (43 techniques)

### Tier 1 Basic — 4/4 PASS
- `last_blank_cell` — pure house scan, set difference
- `full_house` — pure house scan
- `naked_single` — candidate count = 1 check
- `hidden_single` — house_candidates() occurrence check

### Tier 2 Intersections — 9/9 PASS
- `pointing_pair` — block candidate position analysis
- `pointing_triple` — same pattern with 3 cells
- `box_line_reduction` — line-block interaction
- `naked_pair` / `naked_triple` / `naked_quad` — candidate set intersection
- `hidden_pair` / `hidden_triple` / `hidden_quad` — candidate restriction analysis

### Tier 3 Wings/Fish — 12/12 PASS
- `xwing` / `swordfish` / `jellyfish` — row-col candidate matching
- `xywing` / `xyzwing` / `wxyzwing` / `vwxyzwing` — bivalue/trivalue/quadvalue pivot matching
- `wwing` / `mwing` / `swing` / `lwing` / `hwing` — bivalue + strong link patterns

### Tier 4 Uniqueness — 4/4 PASS
- `unique_rectangle` — deadly pattern analysis (Types 1-4)
- `hidden_rectangle` — hidden UR pattern
- `avoidable_rectangle` — avoidable deadly pattern
- `bug` — BUG+1/+2 detection

### Tier 5 Chains — 5/5 PASS
- `simple_coloring` — BFS on candidate-adjacency graph
- `xcycle` — strong-link graph traversal
- `remote_pairs` — DFS chain on bivalue cells (candidate-only checks)
- `xychain` — DFS chain on bivalue cells (candidate-only checks)
- `aic` — strong-link graph with DFS path finding

### Tier 6 ALS — 1/1 PASS
- `alsxz` — ALS set analysis with combinations, no value trying

### Tier 7 Exotic Fish — 4/4 PASS
- `finned_fish` (+ FinnedXWing/Swordfish/Jellyfish) — pure candidate position + block analysis

### Tier 8 Extreme — 2/7 PASS, 5 FAIL
- `empty_rectangle` — ER pattern + strong link analysis
- `sue_de_coq` — stub (returns None)
- `pattern_overlay` — **FAIL** (recursive backtracking with clone)
- `aligned_pair_exclusion` — **FAIL** (clone + place 2 values)
- `forcing_chains` — **FAIL** (clone + place + propagate)
- `nishio` — **FAIL** (delegates to ForcingChains)
- `bowmans_bingo` — **FAIL** (clone + try + propagate, 2-level nesting)

---

## FAILURES (5 techniques)

### FAIL #1: PatternOverlay
**File:** `techniques/extreme/pattern_overlay.py:18-64`

```python
# Recursive backtracking for template verification
def apply(self, board):
    ...
    test = board.clone()          # clone
    if test.place(cell.row, cell.col, d):  # try value
        ...

def _can_place_all(self, board, d, cells):
    for cell in cells:
        test = board.clone()      # clone per attempt (recurse)
        if test.place(cell.row, cell.col, d):
            remaining = test.cells_with_candidate(d)
            if not remaining or self._can_place_all(test, d):
                return True
```

**Issue:** Recursive backtracking search for valid templates. Tries every candidate cell, places value, recurses to place remaining values.

---

### FAIL #2: AlignedPairExclusion
**File:** `techniques/extreme/aligned_pair_exclusion.py:67-71`

```python
def _check_combo(self, board, a, b, va, vb):
    test = board.clone()      # clone
    test.place(a.row, a.col, va)  # try value for cell A
    test.place(b.row, b.col, vb)  # try value for cell B
    return not test.is_valid       # check if contradiction
```

**Issue:** Clones board to test value pairs and detect contradictions via `is_valid`.

---

### FAIL #3: ForcingChains
**File:** `techniques/extreme/forcing_chains.py:38-261`

```python
# Cell Forcing (line 59):
test = board.clone()
if not test.place(cell.row, cell.col, v):
    continue
results = self._propagate_all_singles(test)  # run solver on clone

# Region Forcing (line 148):
test = board.clone()
if not test.place(pos_cell.row, pos_cell.col, d):
    continue

# Contradiction Forcing (line 189):
test = board.clone()
if not test.place(cell.row, cell.col, v):
    continue
if self._leads_to_contradiction(test, depth):
    ...
```

**Issue:** 4 occurrences of clone+place+propagate. The `_propagate_all_singles` (L236-258) runs naked+hidden single placement in a loop — a solver on cloned boards.

> **Note:** The `ForcingChains` docstring literally says "PROHIBIDO backtracking, brute force, o solver oculto" — yet the code does all three.

---

### FAIL #4: Nishio
**File:** `techniques/extreme/nishio.py:18-26`

```python
test = board.clone()  # unused clone
fc = ForcingChains()
contradiction = fc._contradiction_forcing(board)  # delegates to FAIL
```

**Issue:** Delegates to `ForcingChains._contradiction_forcing()` which clones+places. Fails by delegation.

---

### FAIL #5: BowmansBingo
**File:** `techniques/extreme/bowmans_bingo.py:18-64`

```python
# Level 1: try a value on cloned board
test = board.clone()
test.place(cell.row, cell.col, v)
# propagate all singles on clone
while changed:
    for c2 in test.empty_cells():
        if len(c2_cands) == 1:
            test.place(c2.row, c2.col, c2v)

# Level 2: second clone + try
for c2 in test.empty_cells():
    for c2v in candidates:
        test2 = test.clone()       # SECOND clone
        test2.place(c2.row, c2.col, c2v)
        # propagate again...
```

**Issue:** Two-level nested cloning + value trying + propagation on cloned copies. Textbook brute-force guess-and-check.

---

## Root Cause

All 5 failures use the same anti-pattern:

```
board.clone() → test.place() → [propagate | check is_valid] → conclude
```

This is the **solve copy hack**: duplicating the board to try values without affecting the original — which IS a hidden solver.

---

## Recommendations

1. **PatternOverlay** — can be reimplemented with `itertools.product` over candidate sets for template verification without cloning
2. **AlignedPairExclusion** — can check pairwise candidate exclusion using set arithmetic directly on the board's candidate state
3. **ForcingChains** — needs full rewrite using inference chain tracking on the original board's candidate graph, not clone+propagate
4. **Nishio** — same as ForcingChains (fix the delegate)
5. **BowmansBingo** — same as ForcingChains (it's a special case of contradiction forcing)

**Until reimplemented**, these techniques should carry a flag or explicit warning that they use board cloning for inference, making them **non-pure** by the engine's standards.
