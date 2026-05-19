"""
Auditor de puzzles duplicados en assets/boards/
Calcula SHA1 de cada puzzle string y reporta colisiones.
"""
import json
import os
import hashlib

BASE = os.path.normpath(os.path.join(
    os.path.dirname(__file__), "..",
    "flutter_app", "assets", "boards"
))

seen = {}       # sha1 → (diff, filename)
duplicates = [] # (file1, file2, sha1)

for diff in os.listdir(BASE):
    diff_dir = os.path.join(BASE, diff)
    if not os.path.isdir(diff_dir):
        continue
    for fname in sorted(os.listdir(diff_dir)):
        if not fname.endswith(".json"):
            continue
        fpath = os.path.join(diff_dir, fname)
        with open(fpath, encoding="utf-8") as f:
            data = json.load(f)
        puzzle = data.get("puzzle", "")
        sha = hashlib.sha1(puzzle.encode()).hexdigest()[:12]
        label = f"{diff}/{fname}"
        if sha in seen:
            duplicates.append((seen[sha], label, sha))
            print(f"  DUPLICATE: {seen[sha]}  ==  {label}  [sha={sha}]")
        else:
            seen[sha] = label

print(f"\n=== {len(seen)} unique puzzles | {len(duplicates)} duplicates found ===")
if not duplicates:
    print("OK: no duplicates")
