# Mythic Fix Report — BLOCKED

## Scope

- Audited only `flutter_app/assets/boards/mythic/mythic_0001.json` → `mythic_0100.json`.
- Did not modify Mythic board files.
- Did not touch easy/intermediate/hard/expert/evil.
- Did not build Flutter or touch UI.

## Legacy audit result

- Legacy valid: 0
- Legacy invalid: 100
- Exact duplicates: 0
- Geometry duplicates: 0
- Misclassified: 100

See `tools/generator/mythic_legacy_audit.json`.

## Blocker: `forcing_chain` is unreachable in the current solver

`human_solver.py` technique order runs `naked_single` before `forcing_chain`.

Current `forcing_chain.py` only changes candidates when removing a trial value from peers makes an empty cell have zero candidates:

```py
for peer in peers(*cell):
    trial[peer].discard(value)
if any(board[r][c] == 0 and not vals for (r, c), vals in trial.items()):
    candidates[cell].discard(value)
    return TechniqueResult(True, [cell], self.name)
```

For a peer to become empty after discarding `value`, that peer must have had candidates `{value}` before the discard. That is a naked single.

But `naked_single` runs first and places any cell with exactly one candidate:

```py
if board[cell[0]][cell[1]] == 0 and len(values) == 1:
    place(...)
```

Therefore, when `forcing_chain` is reached, the precondition it needs has already been consumed by `naked_single`. Under the current implementation, a valid board solved by `human_solver.py` cannot honestly record `forcing_chain`.

## Generation attempt

A controlled search using `target_generator.generate_target('mythic')` over 300 attempts found no board whose validated human techniques included `forcing_chain`. Most generated profiles were lower-difficulty techniques, confirming the static code analysis.

## Required next step

To create real Mythic boards, we need an approved solver change in `tools/generator/techniques/forcing_chain.py` (or a separate real Mythic technique implementation) so `forcing_chain` models an actual contradiction chain that can fire after singles/pairs/fish/xywing are exhausted.

Until then, generating `mythic_0001` → `mythic_0500` with `forcing_chain: 500/500` would be fake metadata, not real human-solver classification.
