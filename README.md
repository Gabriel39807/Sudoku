# Sudoku

App de Sudoku con Flutter + sistema de generación basado en técnicas humanas.

## Estructura

```
flutter_app/    → App Flutter (UI, gameplay, estadísticas)
tools/          → Pipeline Python (generador, solver, auditor)
```

## Pipeline de generación

```bash
cd tools/generator
python create_mock_boards.py     # Genera 20 boards por dificultad
python check_duplicates.py       # Verifica que no haya puzzles duplicados
```

Los tableros se exportan a `flutter_app/assets/boards/{difficulty}/`.

## Clasificación por técnicas

| Dificultad | Técnicas requeridas |
|---|---|
| Easy | Naked/Hidden Singles |
| Intermediate | Naked/Hidden Pairs, Triples |
| Hard | Pointing Pairs, Box-Line Reduction |
| Expert | X-Wing, Swordfish |
| Evil | XY-Wing, Forcing Chains |
| Mythic | Forcing Chains, Nishio |

## Legacy

El frontend original (LibGDX/Java) fue archivado en `legacy_archive/`. Flutter es ahora la UI definitiva.
