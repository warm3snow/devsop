# coding-style.md 特殊子 Agent 指令

> 本文件作为 `coding-style.md` 子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/coding-style.md`。

---

## 核心目标

把 `.harness/docs/coding-style.md` 从多语言通用模板**裁剪并落实**为本项目实际语言与工具链的编码规范——模板中的 `{{占位符}}` 全部替换为项目真实值，不适用的语言小节整段删除。

---

## 步骤

### 1. 检测项目语言与工具链

- 主语言判定（按证据，不臆造）：
  - Go：`go.mod` 存在
  - Python：`requirements.txt` / `pyproject.toml` / `setup.py` 存在
  - Java：`pom.xml` / `build.gradle` 存在
  - C++：`CMakeLists.txt` / `*.cpp` 存在
  - 前端 / Node：`package.json` 存在
- 多语言仓库：保留实际使用的全部语言小节，删除其余
- 工具链事实采集：
  - 格式化工具：`goimports` / `gofmt`（Go）、`prettier`（JS/TS）、`black`（Python）——以仓库配置文件为准（`.prettierrc` / `pyproject.toml` / `.golangci.yml`）
  - Linter：存在 `.golangci.yml` → 填 `golangci-lint` 并引用该配置；存在 `.eslintrc*` → 填 `eslint`；均无 → 保留 `<!-- TODO(sop.init) -->`
  - pre-commit hook：读 `.git/hooks/pre-commit` 或 `.pre-commit-config.yaml`，确认实际触发的检查命令
- 若仓库根存在 `.codebuddy/rules/coding_style*.md` 或类似编码规范文件：读取并作为权威来源

### 2. 生成 / 更新文档

- 「范围」段：填实际语言；多语言仓库注明前后端 / 脚本是否适用
- §1 强制规范表：`{{gofmt / prettier / black}}`、`{{golangci-lint / eslint / ruff}}`、`{{.golangci.yml / .eslintrc}}` 等占位符全部替换为步骤 1 采集的真实值
- §2 命名规范「各语言约定」：只保留项目实际语言的小节，**整段删除**其他语言（Go/Python/Java/C++ 四选实际）
- §5 错误处理 / §6 资源管理 / §8 类型与零值：同样按语言裁剪语言专属子节
- §11 工具链表：填真实工具与触发时机（与 pre-commit hook / CI 配置一致）
- 阈值类条款（行长 ≤120、函数 ≤80 行、圈复杂度 ≤10 等）：若项目 lint 配置中已有不同阈值，以 lint 配置为准并更新；否则保留模板默认值
- 「参考」段：修正失效链接（如 `testing.md` 已迁移为 `unittest/unittest.md`，`api-standards.md` 在 `apis/` 子目录）

### 3. 框架特化（条件触发）

- 若主 Agent 已注入 `references/framework-<name>.md` 的「coding-style.md 子 Agent 额外要求」段（如 go-zero 的目录分层 / 命名 / ServiceContext / errorx 规范）：将这些条款合并进对应章节，标注来源框架

---

## 约束

- 只动 `.harness/docs/coding-style.md`，不动其它 docs
- 所有工具名 / 阈值 / 命令必须来自真实配置文件证据，禁止臆造；无证据的字段保留 `<!-- TODO(sop.init) -->` 占位
- 语言小节裁剪必须整段删除，不留「本项目不涉及」之类的废话
- 若项目已有权威编码规范（`.codebuddy/rules/` 或团队 Wiki 链接）：本文档对应章节改为摘录 + 链接，标注权威来源，不复制冲突内容
- 库项目与常规服务项目均适用，无 skipped 判定；无任何代码文件（纯文档仓库）→ 输出 `skipped(no code)`
