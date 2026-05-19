import sys
import copy
import random
from solver import generate_full_board
from validator import has_unique_solution
from difficulty import classify_difficulty
from export import export_board
from human_solver import solve_human

TARGETS = {
    "easy": 500,
    "intermediate": 500,
    "hard": 500,
    "expert": 500,
    "evil": 300,
    "mythic": 100
}

def validate_techniques(diff, techs):
    if diff == "easy":
        return not any(t in techs for t in ["naked_pair", "hidden_pair", "naked_triple", "pointing_pair", "xwing", "swordfish", "xywing", "forcing_chains"])
    if diff == "intermediate":
        return any(t in techs for t in ["naked_pair", "hidden_pair", "naked_triple"]) and not any(t in techs for t in ["pointing_pair", "xwing", "swordfish", "xywing", "forcing_chains"])
    if diff == "hard":
        return any(t in techs for t in ["pointing_pair", "box_line_reduction"]) and not any(t in techs for t in ["xwing", "swordfish", "xywing", "forcing_chains"])
    if diff == "expert":
        return any(t in techs for t in ["xwing", "swordfish"]) and not any(t in techs for t in ["xywing", "forcing_chains"])
    if diff == "evil":
        return any(t in techs for t in ["xywing", "xyzwing", "forcing_chains"])
    if diff == "mythic":
        return any(t in techs for t in ["forcing_chains", "nishio"])
    return False

def generate_boards():
    counts = {k: 0 for k in TARGETS.keys()}
    
    total_needed = sum(TARGETS.values())
    total_generated = 0
    
    while total_generated < total_needed:
        solution = generate_full_board()
        puzzle = copy.deepcopy(solution)
        
        positions = [(r, c) for r in range(9) for c in range(9)]
        random.shuffle(positions)
        
        for r, c in positions:
            temp = puzzle[r][c]
            if temp == 0: continue
            
            puzzle[r][c] = 0
            if not has_unique_solution(puzzle):
                puzzle[r][c] = temp 
                
        diff = classify_difficulty(puzzle)
        human_result = solve_human(puzzle)
        techs = human_result["techniques"]
        steps = human_result["steps"]
        
        is_valid = validate_techniques(diff, techs)
        
        print(f"generated puzzle candidate")
        print(f"techniques: {', '.join(techs) if techs else 'none'}")
        print(f"steps: {steps}")
        print(f"classified as: {diff}")
        
        if is_valid and diff in counts and counts[diff] < TARGETS[diff]:
            counts[diff] += 1
            total_generated += 1
            board_id = f"{diff}_{counts[diff]:04d}"
            export_board(board_id, diff, puzzle, solution, techniques=techs, steps=steps)
            print(f"-> accepted as {board_id} ({counts[diff]}/{TARGETS[diff]})\n")
        else:
            print("-> rejected\n")
            
if __name__ == "__main__":
    print("Starting generation pipeline...")
    generate_boards()
    print("Generation complete.")
