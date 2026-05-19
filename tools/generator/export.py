import json
import os

def export_board(board_id, difficulty, puzzle_grid, solution_grid, techniques=None, steps=0):
    if techniques is None: techniques = []
    puzzle_str = "".join(str(val) for row in puzzle_grid for val in row)
    solution_str = "".join(str(val) for row in solution_grid for val in row)
    
    data = {
        "id": board_id,
        "difficulty": difficulty,
        "techniques": techniques,
        "steps": steps,
        "puzzle": puzzle_str,
        "solution": solution_str
    }
    
    base_dir = os.path.join("..", "..", "flutter_app", "assets", "boards")
    os.makedirs(base_dir, exist_ok=True)
    
    diff_dir = os.path.join(base_dir, difficulty)
    os.makedirs(diff_dir, exist_ok=True)
    
    file_path = os.path.join(diff_dir, f"{board_id}.json")
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)
