DIFFICULTY_ORDER = ["easy", "intermediate", "hard", "expert", "evil", "mythic"]

CATEGORY = {
    "naked_single": "easy",
    "hidden_single": "easy",
    "naked_pair": "intermediate",
    "hidden_pair": "intermediate",
    "naked_triple": "intermediate",
    "hidden_triple": "intermediate",
    "pointing_pair": "hard",
    "box_line_reduction": "hard",
    "xwing": "expert",
    "swordfish": "expert",
    "xywing": "evil",
    "forcing_chain": "mythic",
}


def classify_by_techniques(techniques):
    categories = {CATEGORY[t] for t in techniques if t in CATEGORY}
    if not categories:
        return None
    highest = max(categories, key=DIFFICULTY_ORDER.index)
    if highest == "easy":
        return "easy"
    if highest == "intermediate" and categories <= {"easy", "intermediate"}:
        return "intermediate"
    if highest == "hard" and categories <= {"easy", "intermediate", "hard"}:
        return "hard"
    if highest == "expert" and categories <= {"easy", "intermediate", "hard", "expert"}:
        return "expert"
    if highest == "evil" and categories <= {"easy", "intermediate", "hard", "expert", "evil"}:
        return "evil"
    if highest == "mythic":
        return "mythic"
    return None


def classification_matches(expected, techniques):
    return classify_by_techniques(techniques) == expected
