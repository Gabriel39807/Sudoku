from solver import count_solutions

def has_unique_solution(grid):
    count = [0]
    count_solutions(grid, count)
    return count[0] == 1
