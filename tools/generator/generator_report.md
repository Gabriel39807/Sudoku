# Generator Report — Post-Refactor

## Resumen

Refactor completo del generador Sudoku. Se eliminaron **heurísticas falsas** (`place_from_solution`, `_solve_copy`, `empty_count % 7`) de las técnicas avanzadas. Ahora todas las técnicas son **implementaciones reales** de resolución humana.

## Dataset Actual (600 boards)

| Dificultad    | Válidos | Inválidos |
|---------------|---------|-----------|
| easy          | 100     | 0         |
| intermediate  | 100     | 0         |
| hard          | 100     | 0         |
| expert        | 1       | 99        |
| evil          | 0       | 100       |
| mythic        | 0       | 100       |

**Total: 301 válidos, 299 inválidos**

### Causa de inválidos

Los 299 boards expert/evil/mythic fueron generados con el **sistema viejo** que usaba `place_from_solution` — backtracking disfrazado de técnica humana. Al eliminar esas heurísticas, el solver humano revela que esos boards **no son realmente resolubles** con técnicas humanas puras.

## Errores encontrados

- **299 boards** no resolubles por solver humano (expert/evil/mythic)
- **0 duplicados** (hash SHA256 único)
- **0 clasificaciones incorrectas** (los boards válidos tienen su dificultad correcta)
- **0 conflictos** en puzzles y soluciones

## Técnicas implementadas (12 reales)

| Técnica           | Archivo                    | Peso |
|-------------------|----------------------------|------|
| Naked Single      | `naked_single.py`          | 1    |
| Hidden Single     | `hidden_single.py`         | 1    |
| Naked Pair        | `naked_pair.py`            | 2    |
| Hidden Pair       | `hidden_pair.py`           | 2    |
| Naked Triple      | `naked_triple.py`          | 3    |
| Hidden Triple     | `hidden_triple.py`         | 3    |
| Pointing Pair     | `pointing_pair.py`         | 4    |
| Box Line Reduction| `box_line_reduction.py`    | 4    |
| X-Wing            | `xwing.py`                 | 5    |
| Swordfish         | `swordfish.py`             | 6    |
| XY-Wing           | `xywing.py`                | 7    |
| Forcing Chain     | `forcing_chain.py`         | 8    |

**Eliminado**: `place_from_solution`, `_solve_copy`, `empty_count(board) % 7`.

## Tests (44 tests)

```
Ran 44 tests in 0.127s
OK
```

- solver: 5 tests
- human solver: 5 tests
- validator: 7 tests
- classification: 9 tests
- duplicates: 4 tests
- export: 4 tests
- to_grid: 6 tests
- technique helpers: 4 tests

## Estructura final

```
tools/generator/
├── audit/
│   ├── __init__.py
│   └── audit_existing_dataset.py   # Auditoría completa del dataset
├── techniques/
│   ├── __init__.py
│   ├── base.py                     # Foundation: Cell, Board, Candidates, peers, units, place, remove_values
│   ├── naked_single.py             # Implementación real (1 cell con 1 candidato)
│   ├── hidden_single.py            # Implementación real (1 cell en unit con 1 candidato único)
│   ├── naked_pair.py               # Implementación real (2 cells con 2 candidatos compartidos)
│   ├── hidden_pair.py              # Implementación real (2 candidatos solo en 2 cells)
│   ├── naked_triple.py             # Implementación real (3 cells con 3 candidatos compartidos)
│   ├── hidden_triple.py            # Implementación real (3 candidatos solo en 3 cells)
│   ├── pointing_pair.py            # Implementación real (box-line intersección)
│   ├── box_line_reduction.py       # Implementación real (line-box intersección)
│   ├── xwing.py                    # Implementación real (fish de tamaño 2)
│   ├── swordfish.py                # Implementación real (fish de tamaño 3)
│   ├── xywing.py                   # Implementación real (pivot + wings bivalue)
│   └── forcing_chain.py            # Implementación real (contradiction chains)
├── checkpoints.py                  # Sistema de checkpoints por fase
├── classify_by_techniques.py       # Clasificador por técnicas (CATEGORY mapping + strict)
├── export.py                       # Export con SHA256, hash field, dedup global
├── generate.py                     # Pipeline de generación (seed + random_transform)
├── human_solver.py                 # Solver humano puro (12 técnicas en orden, 0 backtracking)
├── solver.py                       # Backtracking solver (solo para validar unicidad)
├── validator.py                    # Backtracking utilities (find_empty, count_solutions, solve)
├── validator_final.py              # Validador completo (unicidad, conflictos, clasificación, solver humano)
├── test_generator.py               # 44 tests unitarios
├── generator_report.md             # Este archivo
└── dataset_report.json             # Reporte de auditoría
```

## Estado del generador

- **Pipeline**: `generate_board()` → `random_transform()` → `export_board()` con SHA256 dedup
- **Clasificación**: por técnicas reales, no por cantidad de vacíos o clues
- **Validación**: solución única, sin conflictos, clasificación correcta, sin duplicados, resoluble humano
- **Checkpoints**: sistema de fases (save/load/clear) para continuar desde donde se quedó
- **Export**: SHA256(81-char puzzle) como hash único, sin campo `checksum` legacy

## Próximo paso

Regenerar todos los datasets con el pipeline nuevo:
1. Generar +400 boards por dificultad (easy → mythic)
2. Validar cada board con `validate_board()`
3. Rechazar duplicados vía SHA256
4. Generar IDs secuenciales (`expert_0001.json`)
5. Verificar con auditoría final

**Dataset intacto** — solo se reportaron los problemas, no se modificaron los boards existentes.
