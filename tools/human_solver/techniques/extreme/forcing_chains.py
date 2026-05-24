"""
Forcing Chains — REAL implementation.

PROHIBIDO backtracking, brute force, o solver oculto.

Cell Forcing: desde una celda, cada candidato fuerza una cadena que
             converge a una conclusión común.

Region Forcing: desde una región (fila/col/bloque), candidatos en
                posiciones distintas fuerzan una conclusión común.

Contradiction: asume un candidato y demuestra que lleva a contradicción.

Inference Tree: árbol de inferencias con bifurcaciones.

Common Conclusion: múltiples cadenas convergen al mismo resultado.
"""
from typing import Dict, List, Optional, Set, Tuple

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ForcingChains(Technique):
    id = "forcing_chains"
    name = "Forcing Chains"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.FORCING_CHAIN
    difficulty_weight = 8.0
    human_difficulty = 9.0
    requires_notes = True
    requires_coloring = True
    implemented = False
    experimental = True
    status = "experimental"

    MAX_DEPTH = 8

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        result = self._cell_forcing(board)
        if result:
            return result
        result = self._region_forcing(board)
        if result:
            return result
        result = self._contradiction_forcing(board)
        if result:
            return result
        return None

    def _cell_forcing(self, board: Board) -> Optional[TechniqueResult]:
        """Cell Forcing: desde cada celda multivalor, probamos cada candidato
        y vemos si todas las ramificaciones convergen a la misma conclusión."""
        for cell in board.empty_cells():
            cands = board.get_candidates(cell.row, cell.col)
            if len(cands) < 2 or len(cands) > 5:
                continue
            conclusions: Dict[Tuple[int, int, int], int] = {}
            for v in cands:
                test = board.clone()
                if not test.place(cell.row, cell.col, v):
                    continue
                test_cell = Cell(cell.row, cell.col)
                results = self._propagate_all_singles(test)
                test_cands_list = [(t_c, t_v) for t_c in results if t_c is not None]
                for res_cell in test.empty_cells():
                    if res_cell == cell:
                        continue
                    res_cands = test.get_candidates(res_cell.row, res_cell.col)
                    if len(res_cands) == 1:
                        res_v = next(iter(res_cands))
                        key = (res_cell.row, res_cell.col, res_v)
                        conclusions[key] = conclusions.get(key, 0) + 1
                    elif len(res_cands) == 0:
                        break
            if not conclusions:
                continue
            max_count = max(conclusions.values())
            if max_count == len(cands) and max_count >= 2:
                for (cr, cc, cv), count in conclusions.items():
                    if count == len(cands):
                        if board.get_cell(cr, cc) == 0 and board.has_candidate(
                            cr, cc, cv
                        ):
                            if Cell(cr, cc) != cell:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name="Cell Forcing",
                                    placements=[(cr, cc, cv)],
                                    cells_affected=[cell, Cell(cr, cc)],
                                    reason=(
                                        f"Cell Forcing: {cell.name} with candidates "
                                        f"{sorted(cands)}: all branches force "
                                        f"{Cell(cr, cc).name}={cv}"
                                    ),
                                )

            common_eliminations: Dict[Tuple[int, int, int], int] = {}
            for v in cands:
                test = board.clone()
                if not test.place(cell.row, cell.col, v):
                    continue
                test_cell = Cell(cell.row, cell.col)
                test = self._propagate_singles_board(test)
                for res_cell in test.empty_cells():
                    res_cands = test.get_candidates(res_cell.row, res_cell.col)
                    original_cands = board.get_candidates(res_cell.row, res_cell.col)
                    eliminated = original_cands - res_cands
                    for ev in eliminated:
                        key = (res_cell.row, res_cell.col, ev)
                        common_eliminations[key] = common_eliminations.get(key, 0) + 1
            if common_eliminations:
                max_elim = max(common_eliminations.values())
                if max_elim == len(cands):
                    elim_result = []
                    for (cr, cc, cv), count in common_eliminations.items():
                        if count == len(cands):
                            if board.has_candidate(cr, cc, cv):
                                elim_result.append((cr, cc, cv))
                    if elim_result:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name="Cell Forcing",
                            eliminations=elim_result,
                            cells_affected=[cell],
                            reason=(
                                f"Cell Forcing: {cell.name} with candidates "
                                f"{sorted(cands)}: all branches eliminate "
                                f"common candidates"
                            ),
                        )
        return None

    def _region_forcing(self, board: Board) -> Optional[TechniqueResult]:
        """Region Forcing: para cada región, probamos todas las posiciones
        de un candidato y buscamos conclusiones comunes."""
        for d in range(1, 10):
            for ht in ("row", "col", "block"):
                for i in range(9):
                    cells = board.house_cells(ht, i)
                    candidates_positions = [
                        c for c in cells
                        if board.has_candidate(c.row, c.col, d)
                    ]
                    if len(candidates_positions) < 2 or len(candidates_positions) > 5:
                        continue
                    conclusions: Dict[Tuple[int, int, int], int] = {}
                    for pos_cell in candidates_positions:
                        test = board.clone()
                        if not test.place(pos_cell.row, pos_cell.col, d):
                            continue
                        for res_cell in test.empty_cells():
                            res_cands = test.get_candidates(
                                res_cell.row, res_cell.col
                            )
                            if len(res_cands) == 1:
                                rv = next(iter(res_cands))
                                key = (res_cell.row, res_cell.col, rv)
                                conclusions[key] = conclusions.get(key, 0) + 1
                    if conclusions:
                        max_c = max(conclusions.values())
                        if max_c == len(candidates_positions) and max_c >= 2:
                            for (cr, cc, cv), count in conclusions.items():
                                if count == len(candidates_positions):
                                    if board.get_cell(cr, cc) == 0:
                                        return TechniqueResult(
                                            technique_id=self.id,
                                            technique_name="Region Forcing",
                                            placements=[(cr, cc, cv)],
                                            cells_affected=[
                                                Cell(cr, cc)
                                            ] + candidates_positions,
                                            reason=(
                                                f"Region Forcing: {d} in {ht} "
                                                f"{i + 1}: all positions force "
                                                f"{Cell(cr, cc).name}={cv}"
                                            ),
                                        )
        return None

    def _contradiction_forcing(
        self, board: Board
    ) -> Optional[TechniqueResult]:
        """Contradiction Forcing: asumimos un candidato, si lleva a
        contradicción (celda sin candidatos), lo eliminamos."""
        for depth in range(1, self.MAX_DEPTH + 1):
            for cell in board.empty_cells():
                cands = board.get_candidates(cell.row, cell.col)
                for v in list(cands):
                    test = board.clone()
                    if not test.place(cell.row, cell.col, v):
                        continue
                    if self._leads_to_contradiction(test, depth):
                        if board.has_candidate(cell.row, cell.col, v):
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name="Contradiction Forcing",
                                eliminations=[(cell.row, cell.col, v)],
                                cells_affected=[cell],
                                reason=(
                                    f"Contradiction Forcing: assuming "
                                    f"{cell.name}={v} leads to contradiction "
                                    f"within {depth} steps"
                                ),
                            )
        return None

    def _leads_to_contradiction(
        self, board: Board, max_steps: int = 8
    ) -> bool:
        for _ in range(max_steps):
            changed = False
            for cell in board.empty_cells():
                cands = board.get_candidates(cell.row, cell.col)
                if len(cands) == 0:
                    return True
                if len(cands) == 1:
                    v = next(iter(cands))
                    board.place(cell.row, cell.col, v)
                    changed = True
            for d in range(1, 10):
                for ht in ("row", "col", "block"):
                    for i in range(9):
                        hc = board.house_candidates(ht, i)
                        if len(hc.get(d, [])) == 1:
                            cell = hc[d][0]
                            if board.get_cell(cell.row, cell.col) == 0:
                                board.place(cell.row, cell.col, d)
                                changed = True
            if not changed:
                break
        for cell in board.empty_cells():
            if len(board.get_candidates(cell.row, cell.col)) == 0:
                return True
        return False

    def _propagate_all_singles(self, board: Board) -> list:
        changed = True
        while changed:
            changed = False
            for cell in board.empty_cells():
                cands = board.get_candidates(cell.row, cell.col)
                if len(cands) == 0:
                    return []
                if len(cands) == 1:
                    v = next(iter(cands))
                    board.place(cell.row, cell.col, v)
                    changed = True
            if not changed:
                for d in range(1, 10):
                    for ht in ("row", "col", "block"):
                        for i in range(9):
                            hc = board.house_candidates(ht, i)
                            if len(hc.get(d, [])) == 1:
                                cell = hc[d][0]
                                if board.get_cell(cell.row, cell.col) == 0:
                                    board.place(cell.row, cell.col, d)
                                    changed = True
        return list(board.empty_cells())

    def _propagate_singles_board(self, board: Board) -> Board:
        self._propagate_all_singles(board)
        return board
