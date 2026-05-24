from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class RemotePairs(Technique):
    id = "remote_pairs"
    name = "Remote Pairs"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 5.5
    human_difficulty = 6.5
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        bivalue = board.bivalue_cells()
        for a in bivalue:
            a_cands = sorted(board.get_candidates(a.row, a.col))
            if len(a_cands) != 2:
                continue
            for b in bivalue:
                if b == a:
                    continue
                b_cands = sorted(board.get_candidates(b.row, b.col))
                if b_cands != a_cands:
                    continue
                if a.shares_house(b):
                    continue
                chain = self._find_chain(board, a, b, set(a_cands), set())
                if chain and len(chain) >= 3:
                    last = chain[-1]
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell in chain:
                            continue
                        if cell.shares_house(chain[0]) and cell.shares_house(last):
                            for v in a_cands:
                                if board.has_candidate(
                                    cell.row, cell.col, v
                                ):
                                    eliminations.append((cell.row, cell.col, v))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=chain,
                            reason=(
                                f"Remote Pairs: chain of {len(chain)} cells "
                                f"with candidates {a_cands}, "
                                f"eliminating {a_cands}"
                            ),
                        )
        return None

    def _find_chain(
        self, board: Board, current: Cell, target: Cell,
        vals: set, visited: set
    ) -> Optional[list]:
        if current == target and len(visited) >= 2:
            return [current]
        if current in visited:
            return None
        visited = visited | {current}
        for peer in current.peers():
            if peer in visited:
                continue
            if board.get_cell(peer.row, peer.col) != 0:
                continue
            peer_cands = board.get_candidates(peer.row, peer.col)
            if peer_cands == vals:
                result = self._find_chain(board, peer, target, vals, visited)
                if result:
                    return [current] + result
        return None
