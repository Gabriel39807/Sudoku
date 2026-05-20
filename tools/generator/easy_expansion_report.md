# Easy Expansion Report

## Resumen

- **Boards generados**: 400
- **Rechazados (hash duplicado)**: 0
- **Rechazados (validación)**: 0
- **Tiempo total**: 765.3s
- **Tiempo promedio por board**: 1.91s

## Métricas de dificultad

- **Score medio**: 2.0
- **Rango score**: 1–2

## Clues (pistas iniciales)

- **Clues promedio**: 24.6
- **Rango clues**: 23–28

## Steps (pasos del solver humano)

- **Steps promedio**: 2.0
- **Rango steps**: 1–2

## Técnicas detectadas

- **hidden_single**: 395/400 (98.8%)
- **naked_single**: 400/400 (100.0%)

## Resultados por batch

| Batch | Rango | Generados | Intentos | Tiempo |
|-------|-------|-----------|----------|--------|
| 1 | easy_0101–easy_0150 | 50 | 50 | 69.75s |
| 2 | easy_0151–easy_0200 | 50 | 50 | 80.77s |
| 3 | easy_0201–easy_0250 | 50 | 50 | 106.08s |
| 4 | easy_0251–easy_0300 | 50 | 50 | 110.96s |
| 5 | easy_0301–easy_0350 | 50 | 50 | 67.57s |
| 6 | easy_0351–easy_0400 | 50 | 50 | 93.99s |
| 7 | easy_0401–easy_0450 | 50 | 50 | 115.16s |
| 8 | easy_0451–easy_0500 | 50 | 50 | 120.79s |

## Protección de dataset

- **Duplicados evitados (hash)**: 0
- **Hashes únicos en SEEN_HASHES**: 500

## Verificación final

Pendiente ejecutar:

```bash
python audit_dataset.py
python validator_final.py  # o pytest sobre validate_board
pytest
```