# failures.md 特殊子 Agent 指令

> 本文件作为 `failures.md` 子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度 failures.md 子 Agent 时，将本文件内容一并传入。

---

## 额外数据源（在通用步骤 3「扫描项目上下文」之后执行）

除通用上下文扫描外，你还需要从以下来源提取踩坑信息：

### A. Memory 记录

读取 AI Agent 的 Memory/记忆文件（如存在）：
- `.codebuddy/memory/` 目录
- `.claude/` 目录中的记忆文件
- 项目中其他 AI 记忆存储位置（按实际发现的目录处理）

从中提取：
- 修复 Bug 的记录（尤其是反复出现或花费较长时间定位的问题）
- AI 生成代码后被人工纠正的案例
- 明确标注为"坑"、"注意"、"踩过"的经验

### B. Git Log 分析

执行以下命令提取修复类提交（限最近 100 条，避免上下文爆炸）：

```bash
# 提取含修复关键词的提交
git log --oneline --all -n 100 --format="%h %s" 2>/dev/null | \
  grep -i -E "(fix|bug|hotfix|revert|workaround|hack|临时|修复|回滚)" || true

# 提取 revert 提交（通常意味着之前的提交有问题）
git log --oneline --grep="revert" -n 20 2>/dev/null || true
```

从 Git Log 中识别：
- 反复修改同一文件/函数的模式（暗示该区域容易出错）
- revert 后再修复的提交对（说明第一次方案有问题）
- commit message 中包含根因描述的提交

### C. 整合与写入

将从 Memory 和 Git Log 中提取的踩坑信息，按模板格式整理为独立条目：

- 每条条目必须有：日期、上下文、根因、临时绕过、根治方案
- 信息不完整时，已知字段照实填写，未知字段标注 `{{待补充}}`
- 按时间倒序排列（最近的在最上面）
- 如果没有找到任何踩坑信息，保留模板结构但在记录区注明"暂无历史踩坑记录，待后续积累"

## 约束补充

- Git Log 命令失败（如非 git 仓库）时静默跳过，不报错
- Memory 文件不存在时静默跳过
- **不要编造**踩坑记录，只记录有明确证据支撑的条目
- 对于从 Git Log 推断的问题，标注 `来源：git log` 以区分确定性
