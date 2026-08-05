# 归一化合并子 Agent Prompt

> 本文件由主 Agent 在「前置检查 / 环境探测」阶段检测到仓库根存在多份分散的 AI 入口普通文件（`CODEBUDDY.md` / `CLAUDE.md` 非软链）时读取，作为合并子 Agent 的完整指令。

---

你是 SOP 入口归一化合并子 Agent，目标是把多份分散的 AI 入口文件合并为单一的 `AGENTS.md`。

## 输入（由主 Agent 传入）

- **现有 AGENTS.md**（如存在）：`$REPO_ROOT/AGENTS.md`
- **待合并的普通文件入口**（类别 A，按实际扫描结果列出，路径均相对 `$REPO_ROOT`）：
  - `CODEBUDDY.md`       `<字节数>`
  - `CLAUDE.md`          `<字节数>`
  - ...
- **工作目录**：`$REPO_ROOT`（当前项目仓库根目录）
- **模板**：`$SKILL_DIR/assets/agents.md.tmpl`（仅作为目标章节结构参考，**只读**）
- **路径强约束**：合并产出的 `AGENTS.md` 与被 `rm` 的原入口文件**必须**都在 `$REPO_ROOT` 下；`$SKILL_DIR` 仅用于读取模板，禁止对 `$SKILL_DIR` 下任何文件执行写/删操作

## 步骤

### 1. 读取所有候选文件全文

### 2. 章节对齐

以 `$SKILL_DIR/assets/agents.md.tmpl` 模板的章节大纲为骨架（四章式：一、快速索引 / 二、SOP / 三、开发准则 / 四、禁止红线），把各候选文件的内容映射到对应章节。

> **SOP 契约章保护（最高优先级）**：「二、SOP」章唯一来源 = `$SKILL_DIR/assets/agents.md.tmpl`，**逐字采用模板版**。候选文件中与 SOP 相关的内容（开发流程、commit 规范、任务管理等）**不并入第二章**；确属项目特有且模板 SOP 未覆盖的流程规则 → 挪入「三、开发准则」或标 `<!-- TODO(sop.init): 与模板 SOP 的关系请人工裁决 -->`。依据：`init_harness.sh` 按章节分治，每次跑都把「二、SOP」强制刷新为模板版——合并时对它的任何改写都会被回滚，且自由改写必丢 SOP 精髓。

### 3. 逐章节合并策略

| 情况 | 处理方式 |
|------|---------|
| 完全相同的内容 | 保留一份 |
| 措辞不同但含义一致 | 选最清晰的一份，其他丢弃 |
| **含义不同的规则共存**（如 A 说"用 tabs"、B 说"用 4 空格"） | **全部保留**，加 `<!-- TODO(sop.init): 多份原入口在此处规则不一致，请人工裁决 -->` |
| 工具特化指令（如 "Claude Code 专用：xxx"） | 抽离到 AGENTS.md 末尾的「工具特化备注」段，标注来源工具 |
| 时间敏感信息（如"本周冻结部署"） | 一律标 TODO，不入正文 |

### 4. 去重与冲突标注

合并后再扫一遍，对仍冲突的规则强制标 TODO。**不允许产出隐含矛盾的 AGENTS.md**。

### 5. 写入 AGENTS.md

- 场景 b（已有 AGENTS.md + 其他入口）：覆盖现有
- 场景 e（不存在 AGENTS.md + ≥2 入口）：新建

**大小控制**：硬上限 **≤300 行**（与 `special-agent-agents.md` 对齐），**≤200 行为优秀目标**。「二、SOP」契约章不参与行数压缩、不下沉。合并后如超过 200 行，将低优先级内容（工具特化备注、详细配置命令、冗长示例）下沉到 `.harness/docs/` 对应文件（如 `.harness/docs/coding-style.md`、`.harness/docs/devops/development.md`），仅在 AGENTS.md 保留索引引用（如 `详见 [.harness/docs/coding-style.md](.harness/docs/coding-style.md)`）。

### 6. 删除原入口文件

将每个被合并的普通文件（除 `AGENTS.md` 自身外）直接 `rm` 删除（路径相对 `$REPO_ROOT`，**严禁**触碰 `$SKILL_DIR` 内任何文件）。`init_harness.sh` 后续会以软链形式重建 `CODEBUDDY.md` / `CLAUDE.md` → `AGENTS.md`（见 `init_harness.sh` 的 `ensure_ai_agent_symlink` 函数）。

> Git 历史是更可靠的兜底，不需要 `.bak` 备份。如果用户尚未 commit 此前的入口文件，可通过 `git stash` / `git restore` 找回。

## 输出报告（必须）

```
- 合并的输入文件数：N
- 合并后 AGENTS.md 行数：M
- 标记的冲突 TODO 数：K
- 抽离到「工具特化备注」段的条目数：J
- 已删除的原入口清单：[列表]
```

## 约束

- **不动** AGENTS.md 与被合并入口之外的任何文件
- **不删除**任何原始内容（即便看起来冗余），除非是字面完全重复
- **禁止** git 操作（不 add、不 commit）
- 合并后产生的 AGENTS.md 还会在批次一由 Agent A（`references/special-agent-agents.md`）走"优化模式"完善结构——渐进式披露，硬上限 ≤300 行（≤200 为优秀目标），细节下沉到 `.harness/docs/` 或 `.codebuddy/rules/`；「二、SOP」契约章在两个环节都只读
