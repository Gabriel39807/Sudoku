from __future__ import annotations
from typing import Dict, List, Optional


class HumanDifficultyScore:
    def __init__(self, steps: List[dict]):
        self._steps = steps
        self._score = self._calculate()

    def _calculate(self) -> dict:
        if not self._steps:
            return {
                "total_score": 0.0,
                "tier_max": 0,
                "step_count": 0,
                "elimination_count": 0,
                "avg_difficulty_per_step": 0.0,
                "technique_breakdown": {},
                "tier_distribution": {},
                "chain_count": 0,
                "chain_lengths": [],
                "fish_count": 0,
                "label": "Unknown",
            }

        tiers_used = set()
        total_difficulty = 0.0
        techniques = {}
        tier_counts = {}
        chain_lengths = []
        fish_count = 0
        elimination_count = 0

        tier_names = {1: "Basic", 2: "Intersections", 3: "Wings/Fish",
                      4: "Uniqueness", 5: "Chains", 6: "ALS",
                      7: "Exotic Fish", 8: "Extreme"}

        for step in self._steps:
            tier = step["tier"]
            tiers_used.add(tier)
            tid = step["technique_id"]
            delta = step.get("difficulty_delta", 0) or 0
            total_difficulty += delta
            elimination_count += len(step["eliminations"])

            techniques[tid] = techniques.get(tid, 0) + 1
            tier_counts[tier] = tier_counts.get(tier, 0) + 1

            if tid in ("xychain", "remote_pairs"):
                chain_lengths.append(delta)
            if "fish" in tid or tid in ("xwing", "swordfish", "jellyfish"):
                fish_count += 1

        max_tier = max(tiers_used) if tiers_used else 0
        step_count = len(self._steps)
        avg_difficulty = total_difficulty / step_count if step_count > 0 else 0.0

        tier_difficulty_weights = {1: 1, 2: 2, 3: 4, 4: 5, 5: 7, 6: 8, 7: 9, 8: 10}
        tier_weight = tier_difficulty_weights.get(max_tier, 0)

        step_weight = min(step_count / 10, 5.0)
        elim_weight = min(elimination_count / 20, 3.0)
        chain_weight = min(len(chain_lengths) * 0.5, 2.0)

        raw_score = (
            tier_weight * 3.0
            + avg_difficulty * 1.5
            + step_weight * 2.0
            + elim_weight * 1.0
            + chain_weight * 1.5
            + min(fish_count * 0.3, 1.5)
        )

        label = self._classify(raw_score, max_tier, step_count)

        tier_distribution = {}
        for t_num in sorted(tier_names.keys()):
            count = tier_counts.get(t_num, 0)
            if count > 0:
                tier_distribution[tier_names[t_num]] = count

        return {
            "total_score": round(raw_score, 1),
            "tier_max": max_tier,
            "step_count": step_count,
            "elimination_count": elimination_count,
            "avg_difficulty_per_step": round(avg_difficulty, 2),
            "technique_breakdown": dict(sorted(techniques.items(),
                                               key=lambda x: -x[1])),
            "tier_distribution": tier_distribution,
            "chain_count": len(chain_lengths),
            "fish_count": fish_count,
            "label": label,
        }

    def _classify(self, score: float, max_tier: int, steps: int) -> str:
        if max_tier <= 2 and steps < 30:
            return "Very Easy"
        elif max_tier <= 2:
            return "Easy"
        elif max_tier <= 3 and steps < 50:
            return "Medium"
        elif max_tier <= 4:
            return "Medium Hard"
        elif max_tier <= 5:
            return "Hard"
        elif max_tier <= 6:
            return "Very Hard"
        elif max_tier <= 7:
            return "Expert"
        else:
            return "Extreme"

    @property
    def score(self) -> float:
        return self._score["total_score"]

    @property
    def label(self) -> str:
        return self._score["label"]

    @property
    def details(self) -> dict:
        return dict(self._score)

    def summary(self) -> str:
        d = self._score
        lines = [
            f"Difficulty Score: {d['total_score']}",
            f"Label: {d['label']}",
            f"Highest Tier: {d['tier_max']}",
            f"Steps: {d['step_count']}",
            f"Eliminations: {d['elimination_count']}",
            f"Avg Difficulty/Step: {d['avg_difficulty_per_step']}",
        ]
        if d["tier_distribution"]:
            lines.append("Tier Distribution:")
            for name, count in d["tier_distribution"].items():
                lines.append(f"  {name}: {count} step(s)")
        if d["chain_count"]:
            lines.append(f"Chains: {d['chain_count']}")
        if d["fish_count"]:
            lines.append(f"Fish: {d['fish_count']}")
        return "\n".join(lines)

    def __repr__(self) -> str:
        return f"HumanDifficultyScore({self.score}, '{self.label}')"
