#!/usr/bin/env python3
"""
D3 可维护性·规模复杂度 评分脚本

输入：Phase 1 采集的 JSON（指标）
输出：D3 融合得分（基础 60% + 规模复杂度 40%）
"""

import json
import sys
import math
from typing import Dict, Any

class D3ScoreCalculator:
    """D3 可维护性评分计算器"""

    def __init__(self, metrics: Dict[str, Any]):
        self.metrics = metrics
        self.scores = {}
        self.red_lines = {}

    def calculate(self) -> Dict[str, Any]:
        """计算 D3 总分"""
        # 第一步：每个指标计算单独得分
        self.calculate_metric_scores()

        # 第二步：计算 D3_规模复杂度 加权平均
        d3_scale_complexity = self.calculate_scale_complexity_score()

        # 第三步：检查红线
        self.check_red_lines()

        # 第四步：输出完整报告
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
        """计算每个指标的得分（0-100）"""
        # 1. 平均圈复杂度（20%）
        self.scores["avg_cc_score"] = self._score_avg_cc(self.metrics.get("avg_cc", 0))

        # 2. 峰值圈复杂度（15%）
        self.scores["peak_cc_score"] = self._score_peak_cc(self.metrics.get("peak_cc", 0))

        # 3. 认知复杂度（15%）
        self.scores["cognitive_cc_score"] = self._score_cognitive_cc(self.metrics.get("cognitive_cc", 0))

        # 4. 代码规模 SLOC（20%）
        self.scores["sloc_score"] = self._score_sloc(self.metrics.get("sloc", 0))

        # 5. 函数长度分布（15%）
        self.scores["function_length_score"] = self._score_function_length(
            self.metrics.get("avg_function_length", 0),
            self.metrics.get("long_functions", 0),
            self.metrics.get("function_count", 1)
        )

        # 6. 可维护性指数 MI（15%）
        self.scores["mi_score"] = self._score_mi(self.metrics.get("mi", 65))

    def calculate_scale_complexity_score(self) -> float:
        """计算 D3_规模复杂度 的加权平均分"""
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
        """检查 D3 新增红线"""
        self.red_lines = {
            "triggered": [],
            "details": []
        }

        # 红线 1：单函数 CC > 50
        if self.metrics.get("peak_cc", 0) > 50:
            self.red_lines["triggered"].append("single_function_cc_gt_50")
            self.red_lines["details"].append({
                "rule": "single_function_cc_gt_50",
                "description": f"存在单函数圈复杂度 > 50（当前：{self.metrics['peak_cc']}），不可测",
                "severity": "critical"
            })

        # 红线 2：平均 CC > 25
        if self.metrics.get("avg_cc", 0) > 25:
            self.red_lines["triggered"].append("avg_cc_gt_25")
            self.red_lines["details"].append({
                "rule": "avg_cc_gt_25",
                "description": f"平均圈复杂度 > 25（当前：{self.metrics['avg_cc']:.1f}），结构混乱",
                "severity": "critical"
            })

        # 红线 3：单文件 SLOC > 2000
        if self.metrics.get("sloc", 0) > 2000:
            self.red_lines["triggered"].append("sloc_gt_2000")
            self.red_lines["details"].append({
                "rule": "sloc_gt_2000",
                "description": f"代码规模 > 2000 行（当前：{self.metrics['sloc']}），巨兽文件",
                "severity": "critical"
            })

    def generate_notes(self) -> list:
        """生成改进建议"""
        notes = []

        if self.scores.get("avg_cc_score", 0) < 75:
            notes.append({
                "dimension": "Avg CC",
                "priority": "high",
                "suggestion": "降低平均圈复杂度，使用 guard clause 和 early return",
                "target": "Avg CC ≤ 10"
            })

        if self.scores.get("sloc_score", 0) < 75:
            notes.append({
                "dimension": "SLOC",
                "priority": "high",
                "suggestion": "拆分超大文件，单文件目标 ≤ 800 行",
                "target": "SLOC ≤ 800"
            })

        if self.scores.get("mi_score", 0) < 75:
            notes.append({
                "dimension": "MI",
                "priority": "medium",
                "suggestion": "提高代码可维护性，目标 MI ≥ 65",
                "target": "MI ≥ 65"
            })

        return notes

    # ─────────────────────────────────────────────
    # 各指标得分方法
    # ─────────────────────────────────────────────

    def _score_avg_cc(self, avg_cc: float) -> float:
        """平均圈复杂度得分"""
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
        """峰值圈复杂度得分"""
        if peak_cc <= 10:
            return 100
        elif peak_cc <= 20:
            return 75
        elif peak_cc <= 50:
            return 50
        else:
            return 0

    def _score_cognitive_cc(self, cognitive_cc: float) -> float:
        """认知复杂度得分"""
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
        """代码规模得分"""
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
        """函数长度得分"""
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

        # 根据超长函数比例调整
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
        """可维护性指数得分"""
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
    """主入口"""
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

    # 输出 JSON
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
