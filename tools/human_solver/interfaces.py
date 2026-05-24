from __future__ import annotations
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Tuple

from human_solver.board import Board


class ISolver(ABC):
    @abstractmethod
    def solve(
        self, board: Board, max_iterations: int = 1000
    ) -> Tuple[bool, Board]:
        ...

    @abstractmethod
    def reset(self) -> None:
        ...


class IClassifier(ABC):
    @abstractmethod
    def classify(self, puzzle: str) -> dict:
        ...


class IGenerator(ABC):
    @abstractmethod
    def generate(
        self, difficulty: str, seed: Optional[int] = None
    ) -> Tuple[str, Board]:
        ...

    @abstractmethod
    def validate(self, puzzle: str) -> bool:
        ...


class IBenchmark(ABC):
    @abstractmethod
    def run(self, puzzles: Dict[str, str]) -> List[dict]:
        ...

    @abstractmethod
    def summary(self) -> str:
        ...


class IExplainer(ABC):
    @abstractmethod
    def explain(self, puzzle: str) -> List[dict]:
        ...
