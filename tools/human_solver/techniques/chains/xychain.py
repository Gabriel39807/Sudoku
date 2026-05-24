from typing import Optional, Set

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class XYChain(Technique):
    id = "xychain"
    name = "XY-Chain"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 6.5
    human_difficulty = 7.5
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        bivalue = board.bivalue_cells()
        for start in bivalue:
            start_cands = sorted(board.get_candidates(start.row, start.col))
            if len(start_cands) != 2:
                continue
            chain = self._build_chain(board, start, start_cands[1], {start}, [start])
            if chain:
                last = chain[-1]
                last_cands = board.get_candidates(last.row, last.col)
                start_first = start_cands[0]
                for cell in board.empty_cells():
                    if cell in chain:
                        continue
                    if cell.shares_house(start) and cell.shares_house(last):
                        if board.has_candidate(
                            cell.row, cell.col, start_first
                        ):
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name,
                                eliminations=[(cell.row, cell.col, start_first)],
                                cells_affected=chain,
                                reason=(
                                    f"XY-Chain: chain of {len(chain)} bivalue cells, "
                                    f"eliminating {start_first} from {cell.name}"
                                ),
                            )
        return None

    def _build_chain(
        self, board: Board, cell: Cell, prev_val: int,
        visited: Set[Cell], chain: list
    ) -> Optional[list]:
        cands = board.get_candidates(cell.row, cell.col)
        next_val = next(v for v in cands if v != prev_val)
        for peer in cell.peers():
            if peer in visited:
                continue
            if board.get_cell(peer.row, peer.col) != 0:
                continue
            peer_cands = board.get_candidates(peer.row, peer.col)
            if len(peer_cands) != 2:
                continue
            if next_val not in peer_cands:
                continue
            if len(chain) >= 3 and peer_cands == board.get_candidates(
                chain[0].row, chain[0].col
            ):
                continue
            new_chain = chain + [peer]
            new_visited = visited | {peer}
            if len(new_chain) >= 3:
                first_cands = board.get_candidates(
                    chain[0].row, chain[0].col
                )
                last_cands = board.get_candidates(peer.row, peer.col)
                if first_cands == last_cands:
                    return new_chain
            result = self._build_chain(
                board, peer, next_val, new_visited, new_chain
            )
            if result:
                return result
        return None
