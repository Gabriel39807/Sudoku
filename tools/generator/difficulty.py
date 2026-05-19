from human_solver import solve_human

def classify_difficulty(grid):
    result = solve_human(grid)
    techs = set(result["techniques"])
    
    if "forcing_chains" in techs or "nishio" in techs:
        return "mythic" if result["steps"] < 10 else "evil" # mock heuristic
    if "xywing" in techs or "xyzwing" in techs:
        return "evil"
    if "xwing" in techs or "swordfish" in techs:
        return "expert"
    if "pointing_pair" in techs or "box_line_reduction" in techs:
        return "hard"
    if "naked_pair" in techs or "hidden_pair" in techs or "naked_triple" in techs:
        return "intermediate"
    
    # Defaults
    if len(techs) == 0: return "mythic" # Couldn't even start = super hard
    return "easy"
