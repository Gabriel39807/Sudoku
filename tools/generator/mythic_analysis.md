# Mythic Forcing Chain Technical Analysis

## Scope

Reviewed:

- `tools/generator/techniques/forcing_chain.py`
- `tools/generator/human_solver.py`
- `tools/generator/target_generator.py`
- `tools/generator/classify_by_techniques.py`
- `tools/generator/validator_final.py`

No dataset assets were modified during this analysis.

## Current behavior

`human_solver.py` applies techniques in this order:

1. Naked Single
2. Hidden Single
3. Naked Pair
4. Hidden Pair
5. Naked Triple
6. Hidden Triple
7. Pointing Pair
8. Box Line Reduction
9. X-Wing
10. Swordfish
11. XY-Wing
12. Forcing Chain

The current `forcing_chain.py` implementation checks each candidate `(cell, value)` by copying the candidates map, removing `value` from every peer of `cell`, and declaring a contradiction if any unsolved cell has zero candidates.

In simplified terms:

```py
trial = copy(candidates)
for peer in peers(cell):
    trial[peer].discard(value)
if any(empty unsolved candidate set):
    remove value from cell
```

## Why the current forcing_chain never activates

For removing `value` from a peer to make that peer's candidate set empty, that peer must have had exactly `{value}` before the removal.

That is a naked single.

But `NakedSingle` is the first technique in `TECHNIQUE_ORDER`. Any singleton candidate is placed before `ForcingChain` gets a turn. Therefore, the current `forcing_chain` waits for a state that the solver consumes earlier in the same loop.

That's the core bug: the implementation is not a forcing chain; it is a delayed singleton contradiction check.

## What state it expects

The current implementation expects this state:

- Some candidate `(r, c) = value` is hypothetically true.
- That would remove `value` from peers.
- One peer has no remaining candidates after this removal.

But because the only way a single removal can empty a peer is if the peer had exactly `{value}`, the expected state is equivalent to “there is already a naked single peer”.

## What naked_single removes before forcing_chain

`naked_single.py` places any unsolved cell with one candidate:

```py
if board[cell[0]][cell[1]] == 0 and len(values) == 1:
    place(board, candidates, cell, next(iter(values)))
```

So by the time the solver reaches `ForcingChain`, no useful singleton-driven contradiction remains.

## Required change

A real forcing chain must simulate logical consequences of an assumption, not just remove one candidate from peers.

Minimum viable human-logic behavior:

1. Pick a bivalue or small candidate `(cell, value)`.
2. Assume the candidate is true.
3. Propagate consequences using deterministic candidate logic:
   - placing singles created by the assumption,
   - removing placed values from peers,
   - detecting candidate contradictions,
   - optionally tracking candidate eliminations.
4. Assume an alternate candidate for the same cell.
5. Propagate consequences again.
6. If one branch contradicts, eliminate the impossible candidate from the original cell.
7. If both branches force the same candidate elimination elsewhere, apply that common elimination.
8. Return structured details: technique name, cells involved, eliminations, and depth.

This is not full backtracking if bounded and used only to derive one logical elimination. It must not solve the whole puzzle recursively or guess its way to a full solution.

## Integration requirement

Keep the human order:

Singles → Pairs → Triples → Pointing → Box Line → XWing → Swordfish → XYWing → ForcingChain

`human_solver.py` must preserve all techniques used and expose logs for forcing-chain triggers:

- `FORCING_CHAIN_TRIGGERED`
- `depth=`
- `cells=`
- `removed=`

## Benchmark gate

Before generating Mythic assets, run `tools/generator/benchmark_mythic.py` for 300 controlled attempts and write `tools/generator/mythic_benchmark.json`.

If `forcing_chain_hits == 0`, stop and do not export boards.
