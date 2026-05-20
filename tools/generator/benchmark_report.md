# Benchmark Report — Target Generator

Run: 50 boards per difficulty, max 20 attempts each

| Difficulty | Success | Accept% | Avg Time | Avg Score | Avg Steps | Avg Removed |
|------------|---------|---------|----------|-----------|-----------|-------------|
| easy | 50/50 | 100.0% | 0.76s | 2.0 | 2.0 | 56.3 |
| intermediate | 50/50 | 100.0% | 0.966s | 3.0 | 2.3 | 56.4 |
| hard | 50/50 | 100.0% | 0.978s | 3.8 | 2.5 | 56.4 |
| expert | 50/50 | 100.0% | 0.866s | 3.7 | 2.5 | 56.4 |
| evil | 50/50 | 100.0% | 0.963s | 6.4 | 2.7 | 56.5 |
| mythic | 50/50 | 100.0% | 1.114s | 6.3 | 2.9 | 57.0 |

## Techniques per difficulty

### easy
- hidden_single: 50/50 (100%)
- naked_single: 50/50 (100%)

### intermediate
- hidden_pair: 4/50 (8%)
- hidden_single: 50/50 (100%)
- naked_pair: 12/50 (24%)
- naked_single: 50/50 (100%)
- naked_triple: 1/50 (2%)

### hard
- box_line_reduction: 2/50 (4%)
- hidden_pair: 6/50 (12%)
- hidden_single: 50/50 (100%)
- naked_pair: 14/50 (28%)
- naked_single: 50/50 (100%)
- naked_triple: 1/50 (2%)
- pointing_pair: 3/50 (6%)

### expert
- hidden_pair: 4/50 (8%)
- hidden_single: 49/50 (98%)
- hidden_triple: 1/50 (2%)
- naked_pair: 16/50 (32%)
- naked_single: 50/50 (100%)
- naked_triple: 1/50 (2%)
- pointing_pair: 4/50 (8%)

### evil
- box_line_reduction: 3/50 (6%)
- hidden_pair: 8/50 (16%)
- hidden_single: 48/50 (96%)
- naked_pair: 12/50 (24%)
- naked_single: 50/50 (100%)
- pointing_pair: 7/50 (14%)
- xwing: 1/50 (2%)
- xywing: 5/50 (10%)

### mythic
- box_line_reduction: 3/50 (6%)
- hidden_pair: 10/50 (20%)
- hidden_single: 50/50 (100%)
- naked_pair: 16/50 (32%)
- naked_single: 50/50 (100%)
- naked_triple: 3/50 (6%)
- pointing_pair: 9/50 (18%)
- xwing: 1/50 (2%)
- xywing: 3/50 (6%)

## Verdict
✅ All difficulties generate successfully.