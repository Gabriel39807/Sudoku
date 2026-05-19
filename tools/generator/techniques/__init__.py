# tools/generator/techniques/__init__.py
"""Technique package for human Sudoku solver.
Each technique implements an `apply(grid, candidates)` function returning a dict:
{
  "changed": bool,
  "cells": list of (r, c) affected,
  "difficulty_weight": int (higher = harder)
}
"""
