# v1.0 → v1.1 迁移指南

## 概述

go-quality-scorer v1.1 对 D3 可维护性维度进行了重大扩展，引入了 6 个新的规模和复杂度指标。本指南帮助用户平滑迁移。

---

## 主要变化

### 1. 维度名称更新

```
v1.0  → v1.1
"D3 可维护性"  →  "D3 可维护性·规模复杂度"
```

### 2. D3 新增子指标

| 序号 | 新指标 | 工具 | 权重 | 说明 |
|------|--------|------|------|------|
| 1 | 平均圈复杂度 | gocyclo | 20% | 函数 CC 均值 |
| 2 | 峰值圈复杂度 | gocyclo | 15% | 单函数最大 CC |
| 3 | 认知复杂度 | gocognit | 15% | 嵌套加权 |
| 4 | 代码规模 | scc | 20% | 源代码行数 |
| 5 | 函数长度分布 | scc + 解析 | 15% | 平均函数行数 |
| 6 | 可维护性指数 | Halstead 公式 | 15% | MI 综合指标 |

### 3. 评分融合逻辑

**v1.0**（简单）:
```
D3 = gocyclo_score + style_score
```

**v1.1**（融合）:
```
D3_ScaleComplexity = Weighted_Average(6 new metrics)
D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
```

### 4. 新增红线

| 序号 | 红线条件 | 触发后果 |
|------|---------|---------|
| 7 | 单函数 CC > 50 | 评级 F (失败) |
| 8 | 平均 CC > 25 | 评级 F (失败) |
| 9 | 单文件 SLOC > 2000 | 评级 F (失败) |

---

## 兼容性保证

### ✅ 保持不变的部分

1. **D1-D2, D4-D6 维度** - 评分算法完全相同
2. **总体评分权重** - 六维权重不变（D1 25%, D2 20%, 等）
3. **输出格式基础** - JSON 结构向后兼容
4. **CLI 界面** - 命令行参数相同

### ⚠️ 变化的部分

1. **D3 字段** - `D3` 现在是融合分（不是原始分）
2. **新字段** - 新增 `D3_base` 和 `D3_scale_complexity`
3. **工具依赖** - 需要额外安装 `gocognit` 和 `scc`
4. **评分分布** - D3 平均分可能下降 3-8 分（更严格）

---

## 迁移步骤

### 步骤 1: 更新工具链

```bash
# 安装新增工具
brew install gocognit scc

# 或通过 Go
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/boyter/scc/v3@latest

# 验证安装
gocognit --version
scc --version
```

### 步骤 2: 更新评分脚本

```bash
# 替换旧脚本
cp scripts/go-quality-scorer-v1.1.py /path/to/your/installation/

# 或在 CI/CD 中更新版本号
# from: go-quality-scorer v1.0
# to:   go-quality-scorer v1.1.0
```

### 步骤 3: 运行新评分器

```bash
# 旧命令（仍然有效）
python3 go-quality-scorer.py /path/to/project

# 新命令（推荐）
python3 scripts/go-quality-scorer-v1.1.py /path/to/project -o report-v1.1.json
```

### 步骤 4: 分析对比

```bash
# 查看新旧 D3 评分差异
jq '{
  old_d3: .dimensions.D3_base,
  new_d3: .dimensions.D3_maintainability_scale_complexity,
  diff: (.dimensions.D3_maintainability_scale_complexity - .dimensions.D3_base)
}' report-v1.1.json

# 分析具体指标
jq '.metrics | {avg_cc, peak_cc, cognitive_cc, sloc, mi}' report-v1.1.json
```

---

## 数据迁移

### 历史报告对比

```bash
# 脚本：对比 v1.0 和 v1.1 报告
cat > compare.jq << 'EOF'
{
  timestamp: .timestamp,
  version: .version,
  dimensions: {
    D1: .dimensions.D1_correctness,
    D2: .dimensions.D2_security,
    D3_base: .dimensions.D3_base,
    D3_new: .dimensions.D3_maintainability_scale_complexity,
    D3_delta: (.dimensions.D3_maintainability_scale_complexity - .dimensions.D3_base),
    D4: .dimensions.D4_testing,
    D5: .dimensions.D5_architecture,
    D6: .dimensions.D6_performance
  },
  overall_score: .overall_score,
  rating: .rating
}
EOF

jq -f compare.jq report-v1.1.json > comparison.json
```

### 批量转换

```bash
# 对所有旧报告批量评分
for project_dir in /path/to/projects/*; do
  echo "Evaluating $project_dir..."
  python3 scripts/go-quality-scorer-v1.1.py "$project_dir" \
    "reports/$(basename $project_dir)-v1.1.json"
done
```

---

## 常见迁移问题

### Q1: D3 评分下降 5-10 分，是否正常？

**A**: 是正常的。v1.1 新增了 6 个更严格的指标。建议：
1. 查看 `D3_base` vs `D3_scale_complexity` 的具体差异
2. 对照参考文献 D3-可维护性·规模复杂度 逐一改进
3. 预期 2-4 周内可恢复到接近原水平

### Q2: 部分项目缺少工具输出，怎么办？

**A**: 检查依赖工具：
```bash
# 检查所有工具是否就位
which gocyclo gocognit scc golangci-lint gosec

# 若缺失，补装
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest
go install github.com/boyter/scc/v3@latest
```

### Q3: CI/CD 中使用旧版本脚本会怎样？

**A**: 旧脚本不会识别新维度，会导致：
- 缺少 D3 新指标数据
- 无法生成新红线检查
- 输出格式不完整

建议 CI/CD 环境同步更新到 v1.1.0。

### Q4: 能否保留原 D3 评分，同时新增规模指标？

**A**: 可以通过修改脚本权重：

```python
# 在 go-quality-scorer-v1.1.py 中修改
# D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
# 改为
D3_Final = D3_Base(100%) + D3_ScaleComplexity(0%)  # 100% 原分
# 或
D3_Final = D3_Base(80%) + D3_ScaleComplexity(20%)  # 80% 原分，20% 新指标
```

但不推荐。建议使用默认的 60%/40% 融合比例。

---

## 性能影响

| 操作 | v1.0 | v1.1 | 差异 |
|------|------|------|------|
| 单个项目评分 | ~3-5s | ~5-8s | +2-3s（新工具采集） |
| 100 个项目批量评分 | ~5min | ~8-10min | +3-5min |
| 内存占用 | ~50MB | ~80MB | +30MB |
| 磁盘占用（报告） | ~100KB | ~150KB | +50KB |

**建议**: CI/CD 中可增加超时设置 +10s。

---

## 回滚方案

若需要回到 v1.0：

```bash
# 1. 备份新报告
cp go-quality-report-v1.1.json go-quality-report-v1.1.backup.json

# 2. 恢复旧评分器
cp /backup/go-quality-scorer-v1.0.py scripts/go-quality-scorer.py

# 3. 卸载新工具（可选）
brew uninstall gocognit scc

# 4. 运行旧版本
python3 scripts/go-quality-scorer.py /path/to/project
```

---

## 支持与反馈

- 📖 详见 SKILL.md 和参考文献
- 🐛 发现问题？提交 Issue
- 💡 有改进建议？提交 PR

---

**更新时间**: 2026-06-26  
**版本**: v1.1.0
