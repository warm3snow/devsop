#!/usr/bin/env python3
"""
D3 Maintainability & Scale-Complexity scoring script

Input: JSON collected in Phase 1 (metrics)
Output: D3 fused score (Base 60% + Scale-Complexity 40%)
"""

import json
import sys
import math
from typing import Dict, Any

class D3ScoreCalculator:
    """D3 maintainability score calculator"""

    def __init__(self, metrics: Dict[str, Any]):
        self.metrics = metrics
        self.scores = {}
        self.red_lines = {}

    def calculate(self) -> Dict[str, Any]:
        """Calculate the D3 total score"""
        # Step 1: calculate an individual score for each metric
        self.calculate_metric_scores()

        # Step 2: calculate the D3_scale_complexity weighted average
        d3_scale_complexity = self.calculate_scale_complexity_score()

        # Step 3: check red lines
        self.check_red_lines()

        # Step 4: output the full report
        return {
            "d3_scale_complexity": {
                "metrics": self.metrics,
                "scores": self.scores,
                "d3_scale_complexity_total": round(d3_scale_complexity, 1)
            },
            "red_lines": self.red_lines,
            "notes": self.generate_notes()
        }

    def calculate_metric_scores(self):
        """Calculate the score for each metric (0-100)"""
        # 1. Average cyclomatic complexity (20%)
        self.scores["avg_cc_score"] = self._score_avg_cc(self.metrics.get("avg_cc", 0))

        # 2. Peak cyclomatic complexity (15%)
        self.scores["peak_cc_score"] = self._score_peak_cc(self.metrics.get("peak_cc", 0))

        # 3. Cognitive complexity (15%)
        self.scores["cognitive_cc_score"] = self._score_cognitive_cc(self.metrics.get("cognitive_cc", 0))

        # 4. Code size SLOC (20%)
        self.scores["sloc_score"] = self._score_sloc(self.metrics.get("sloc", 0))

        # 5. Function length distribution (15%)
        self.scores["function_length_score"] = self._score_function_length(
            self.metrics.get("avg_function_length", 0),
            self.metrics.get("long_functions", 0),
            self.metrics.get("function_count", 1)
        )

        # 6. Maintainability Index MI (15%)
        self.scores["mi_score"] = self._score_mi(self.metrics.get("mi", 65))

    def calculate_scale_complexity_score(self) -> float:
        """Calculate the D3_scale_complexity weighted average"""
        weights = {
            "avg_cc_score": 0.20,
            "peak_cc_score": 0.15,
            "cognitive_cc_score": 0.15,
            "sloc_score": 0.20,
            "function_length_score": 0.15,
            "mi_score": 0.15
        }

        total_score = 0
        for key, weight in weights.items():
            total_score += self.scores.get(key, 0) * weight

        return total_score

    def check_red_lines(self):
        """Check the new D3 red lines"""
        self.red_lines = {
            "triggered": [],
            "details": []
        }

        # Red line 1: single-function CC > 50
        if self.metrics.get("peak_cc", 0) > 50:
            self.red_lines["triggered"].append("single_function_cc_gt_50")
            self.red_lines["details"].append({
                "rule": "single_function_cc_gt_50",
                "description": f"a single function has cyclomatic complexity > 50 (current: {self.metrics['peak_cc']}), untestable",
                "severity": "critical"
            })

        # Red line 2: average CC > 25
        if self.metrics.get("avg_cc", 0) > 25:
            self.red_lines["triggered"].append("avg_cc_gt_25")
            self.red_lines["details"].append({
                "rule": "avg_cc_gt_25",
                "description": f"average cyclomatic complexity > 25 (current: {self.metrics['avg_cc']:.1f}), structure is chaotic",
                "severity": "critical"
            })

        # Red line 3: single-file SLOC > 2000
        if self.metrics.get("sloc", 0) > 2000:
            self.red_lines["triggered"].append("sloc_gt_2000")
            self.red_lines["details"].append({
                "rule": "sloc_gt_2000",
                "description": f"code size > 2000 lines (current: {self.metrics['sloc']}), monster file",
                "severity": "critical"
            })

    def generate_notes(self) -> list:
        """Generate improvement suggestions"""
        notes = []

        if self.scores.get("avg_cc_score", 0) < 75:
            notes.append({
                "dimension": "Avg CC",
                "priority": "high",
                "suggestion": "reduce average cyclomatic complexity, use guard clauses and early returns",
                "target": "Avg CC ≤ 10"
            })

        if self.scores.get("sloc_score", 0) < 75:
            notes.append({
                "dimension": "SLOC",
                "priority": "high",
                "suggestion": "split oversized files, target single file ≤ 800 lines",
                "target": "SLOC ≤ 800"
            })

        if self.scores.get("mi_score", 0) < 75:
            notes.append({
                "dimension": "MI",
                "priority": "medium",
                "suggestion": "improve code maintainability, target MI ≥ 65",
                "target": "MI ≥ 65"
            })

        return notes

    # ─────────────────────────────────────────────
    # Per-metric scoring methods
    # ─────────────────────────────────────────────

    def _score_avg_cc(self, avg_cc: float) -> float:
        """Average cyclomatic complexity score"""
        if avg_cc <= 5:
            return 100
        elif avg_cc <= 10:
            return 80
        elif avg_cc <= 15:
            return 60
        elif avg_cc <= 25:
            return 40
        else:
            return 0

    def _score_peak_cc(self, peak_cc: int) -> float:
        """Peak cyclomatic complexity score"""
        if peak_cc <= 10:
            return 100
        elif peak_cc <= 20:
            return 75
        elif peak_cc <= 50:
            return 50
        else:
            return 0

    def _score_cognitive_cc(self, cognitive_cc: float) -> float:
        """Cognitive complexity score"""
        if cognitive_cc <= 10:
            return 100
        elif cognitive_cc <= 15:
            return 80
        elif cognitive_cc <= 25:
            return 60
        elif cognitive_cc <= 35:
            return 40
        else:
            return 20

    def _score_sloc(self, sloc: int) -> float:
        """Code size score"""
        if sloc <= 300:
            return 100
        elif sloc <= 800:
            return 85
        elif sloc <= 1500:
            return 70
        elif sloc <= 2000:
            return 50
        else:
            return 0

    def _score_function_length(self, avg_len: float, long_func: int, total_func: int) -> float:
        """Function length score"""
        if avg_len <= 30:
            base_score = 100
        elif avg_len <= 50:
            base_score = 80
        elif avg_len <= 80:
            base_score = 60
        elif avg_len <= 150:
            base_score = 40
        else:
            base_score = 0

        # adjust based on the ratio of overlong functions
        if total_func > 0:
            long_ratio = long_func / total_func
            if long_ratio > 0.4:
                base_score -= 30
            elif long_ratio > 0.2:
                base_score -= 15
            elif long_ratio > 0.1:
                base_score -= 5

        return max(0, min(100, base_score))

    def _score_mi(self, mi: float) -> float:
        """Maintainability Index score"""
        if mi >= 85:
            return 100
        elif mi >= 65:
            return 85
        elif mi >= 50:
            return 60
        elif mi >= 25:
            return 30
        else:
            return 0


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python3 calculate-d3-score.py <metrics.json>", file=sys.stderr)
        sys.exit(1)

    metrics_file = sys.argv[1]

    try:
        with open(metrics_file, 'r') as f:
            metrics = json.load(f)
    except Exception as e:
        print(f"Error reading metrics file: {e}", file=sys.stderr)
        sys.exit(1)

    calculator = D3ScoreCalculator(metrics)
    result = calculator.calculate()

    # output JSON
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
