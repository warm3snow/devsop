# code-review.md 特殊子 Agent 指令

> 本文件作为 `code-review.md` 子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/code-review.md`。

---

## 核心目标

把 `.harness/docs/code-review.md` 中的 `{{占位符}}` 与通用约定替换为项目真实值（主分支名 / 构建检查命令 / 覆盖率阈值），并划清与顶层 `.harness/review.md` 的边界。

---

## 边界说明（先读）

| 文件 | 定位 | 管控方 |
|------|------|--------|
| `.harness/review.md` | AI Code Review 检查清单（AI 自审 + AI 辅助 Review 用） | skill 管控，项目不自定义 |
| `.harness/docs/code-review.md` | 团队人工 Review 流程规范（提交方约束 / Reviewer 清单 / 合入门槛） | 项目自定义，本 Agent 负责填充 |

两者**互补不合并**：code-review.md 不复制 review.md 的检查项，Reviewer 清单聚焦流程与人工判断项；引用关系上 code-review.md 可在「AI 辅助 Review」节指向 `../../review.md`。

---

## 步骤

### 1. 采集项目事实

- 主分支名：`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || git branch -a` 判定 `main` / `master` / 其他，替换 `{{main / master}}`
- 自查命令：读 `Makefile`（或 `package.json` scripts / CI 配置）确认 `make build` / `make lint` / `make ut` 是否真实存在；不存在则替换为实际命令（如 `go build ./...` / `golangci-lint run` / `go test ./...`）
- 覆盖率阈值：从 CI 配置 / `.golangci.yml` / `Makefile` 中提取实际阈值；无证据保留默认 ≥60%
- commit message 格式：读 `.git/hooks/commit-msg` 或 `commit_msg_check.sh`，确认实际校验的类型列表与 TAPD 单号格式（`--story=<id>` / `--bug=<id>`），与 §1 / §2 条款对齐
- 合入门槛：若项目 CI / GitLab 有明确的 approver 人数配置（`.gitlab-ci.yml` / CODEOWNERS），按实际填充 §5

### 2. 生成 / 更新文档

- 「范围」段：填实际主分支名
- §1 提交方约束 / §2 自查清单：替换为真实命令与阈值；命令不存在对应 Makefile target 时直接写 shell 命令
- §3 Reviewer 检查清单：保留模板结构；若项目无 DB（Agent D 已判定 `skipped(no database)`）→ 删除 SQL 注入相关条目或标注「本项目无 DB，N/A」；框架相关条目（如 go-zero）仅在主 Agent 注入框架上下文时保留
- §5 合入门槛：CI 检查项与真实 CI pipeline 对齐（不存在的检查项删除）
- 「参考」段：修正失效链接（`testing.md` → `unittest/unittest.md`；`api-standards.md` → `apis/api-standards.md`，无 API 项目删除该行）

---

## 约束

- 只动 `.harness/docs/code-review.md`，不动其它 docs、不动顶层 `review.md`
- 命令 / 阈值 / 分支名必须来自真实证据，禁止臆造；无证据字段保留 `<!-- TODO(sop.init) -->`
- 禁止把 review.md 的 AI 检查清单整段复制进来——两文件职责见「边界说明」
- 无 skipped 判定：任何项目都有 Review 流程
