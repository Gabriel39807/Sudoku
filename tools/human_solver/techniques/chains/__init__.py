from tools.human_solver.techniques.chains.simple_coloring import SimpleColoring
from tools.human_solver.techniques.chains.xcycle import XCycle
from tools.human_solver.techniques.chains.grouped_xcycle import GroupedXCycle
from tools.human_solver.techniques.chains.remote_pairs import RemotePairs
from tools.human_solver.techniques.chains.xychain import XYChain
from tools.human_solver.techniques.chains.twinned_xychain import TwinnedXYChain
from tools.human_solver.techniques.chains.aic import AIC
from tools.human_solver.techniques.chains.grouped_aic import GroupedAIC
from tools.human_solver.techniques.chains.medusa3d import Medusa3D
from tools.human_solver.techniques.chains.continuous_loop import ContinuousLoop

__all__ = [
    "SimpleColoring", "XCycle", "GroupedXCycle", "RemotePairs",
    "XYChain", "TwinnedXYChain", "AIC", "GroupedAIC", "Medusa3D",
    "ContinuousLoop",
]
