import random

def is_valid(grid, r, c, val):
    for i in range(9):
        if grid[r][i] == val: return False
        if grid[i][c] == val: return False
    
    br, bc = r // 3 * 3, c // 3 * 3
    for i in range(3):
        for j in range(3):
            if grid[br + i][bc + j] == val: return False
    return True

def solve(grid):
    for r in range(9):
        for c in range(9):
            if grid[r][c] == 0:
                for val in range(1, 10):
                    if is_valid(grid, r, c, val):
                        grid[r][c] = val
                        if solve(grid): return True
                        grid[r][c] = 0
                return False
    return True

def generate_full_board():
    grid = [[0]*9 for _ in range(9)]
    # Fill diagonal boxes first to randomize fast
    for i in range(0, 9, 3):
        nums = list(range(1, 10))
        random.shuffle(nums)
        for r in range(3):
            for c in range(3):
                grid[i+r][i+c] = nums.pop()
    solve(grid)
    return grid

def count_solutions(grid, count=[0]):
    for r in range(9):
        for c in range(9):
            if grid[r][c] == 0:
                for val in range(1, 10):
                    if is_valid(grid, r, c, val):
                        grid[r][c] = val
                        count_solutions(grid, count)
                        if count[0] > 1: return
                        grid[r][c] = 0
                return
    count[0] += 1
