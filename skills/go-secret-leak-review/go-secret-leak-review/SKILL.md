---
name: go-secret-leak-review
description: "对指定 commit 区间的增量代码做隐私泄露专项 Code Review，检测密码/私钥/Token/凭证被打印到日志或标准输出的风险（含结构体整体序列化导致的间接泄露）"
disable-model-invocation: true
---

# go-secret-leak-review Skill

> 增量代码隐私泄露审查器 —— 聚焦「敏感值被打印到日志/输出」这一高危风险，含**间接泄露**（结构体/容器整体序列化打印）。

**版本**: 1.1.0 | **状态**: ✅ 可用

---

## 解决的问题

开发过程中，有人可能把敏感数据打印进日志，包括**直接打印**和**间接泄露**：

```go
// 直接泄露
log.Printf("user login pwd=%s", password)              // ❌ 密码泄露
fmt.Println("private key:", privateKeyPEM)              // ❌ 私钥泄露
zap.S().Infof("token=%s", accessToken)                  // ❌ Token 泄露

// 间接泄露（更隐蔽，本 skill v1.1 新增检测）
type User struct {
    ID       int    `json:"id"`
    Password string `json:"password"`   // ❌ 非 "-"，会被序列化
    Token    string `json:"token"`
}
b, _ := json.Marshal(user); log.Printf("user=%s", b)    // ❌ 等效泄露 password+token
log.Printf("user=%+v", user)                            // ❌ %+v 展开所有字段值
fmt.Println(user)                                       // ❌ 依赖 String()，未脱敏则泄露
```

本 skill 对 **commitA..commitB 区间的增量代码** 做专项审查，通过**子 Agent** 定位泄露位置（文件:行），覆盖：

- `password` / `passwd` / `passphrase` / `pwd` 的值
- 私钥 / 证书（`-----BEGIN ... PRIVATE KEY-----`）
- `token` / `apiKey` / `secretKey` / `accessKey` / `sign` / `auth` 的值
- 数据库连接串含口令、`Authorization` 头原始值
- PII（身份证/手机号/银行卡等个人数据）
- **间接泄露**：含敏感字段的结构体 / map / slice 被 `json.Marshal` / `%v` / `%+v` / 自定义序列化器整体打印，且字段未加 `json:"-"`、类型未实现脱敏 `MarshalJSON`/`String`

审查**仅限隐私泄露**，不做通用 lint / 性能 / 架构评审。与 `go-quality-scorer` 互补、不重复。

敏感数据分级（L0–L4）与脱敏规范以 `references/secret-leak-review-prompt.md` 的「敏感数据分级（L0–L4）与脱敏规范」章节为唯一权威来源。

---

## 快速开始

```bash
SKILL_DIR=skills/go-secret-leak-review

# 步骤 A：抽取代码（写 REPO_ROOT 下的 go-secret-leak-diff.txt）

#   增量模式：commitA..commitB 区间
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitA> <commitB> [--path=subdir] [--out=diff.txt]

#   单 commit 模式：只扫该 commit 相对其父的变更（commitB 传 - 或留空或 single）
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitID> - [--path=subdir] [--out=diff.txt]

#   全量模式：commitA 或 commitB 任一传 all/全部/* → 扫描工作区所有 Go 源码
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo all all [--path=subdir] [--out=diff.txt]
#   等价写法：全部 / * / ALL（大小写不敏感）

# 步骤 B：由调用方（CodeBuddy）派发子 Agent
#   读取 $SKILL_DIR/references/secret-leak-review-prompt.md 作为子 Agent 指令，
#   把上一步的 diff 文本注入，子 Agent 返回 findings JSON（不写盘）。
#   子 Agent 用 Agent tool，run_in_background=true，约束：只读、禁 git 写、禁写文件。

# 步骤 C：汇总为最终报告（写 REPO_ROOT 下的 go-secret-leak-report.json）
#   assemble 的 commit 参数须与 extract 一致（模式由参数识别）
python3 $SKILL_DIR/scripts/review_secret_leak.py assemble \
    /path/to/repo <commitA|commitID|all> <commitB|-|all> --findings=findings.json [--out=report.json]
```

**commit 参数语义**（三种模式自动识别）：
- **增量模式**：`commitA` 与 `commitB` 均为合法 commit。`git diff commitA commitB` 表示 commitB 相对 commitA 的变更（commitA 不含，commitB 含）。两 commit 相同则空区间。
- **单 commit 模式**：`commitA` 为合法 commit，`commitB` 传 `-` / `single` / 留空。等价 `git diff commitA^ commitA`（扫该 commit 相对其父的变更）；根 commit 自动对比空 tree。
- **全量模式**：`commitA` 或 `commitB` 任一为关键字 `all` / `ALL` / `全部` / `*`（大小写不敏感）。扫描工作区所有 git 跟踪的 `.go` 文件（自动排除 `vendor/` / `third_party/` / `*.pb.go` / `_gen.go` / `mocks/`），以伪 diff 格式输出，行号即文件真实行号。建议传 `all all`。

---

## 子 Agent 派发规范（调用方必须遵守）

遵循本仓库约定（仿 `sop.init` / `sop.eval`）：

- **工具**：Agent tool，参数 `run_in_background: true`，`subagent_type` 默认 `general-purpose`。
- **注入子 Agent 的输入**：
  - `REPO_ROOT`：目标仓库绝对路径（仅用于按需 `git show`/`git blame` 读上下文）。
  - `DIFF_TEXT`：步骤 A 抽取的增量 diff 全文。
  - 指令文件路径：`$SKILL_DIR/references/secret-leak-review-prompt.md`（子 Agent 读取并遵循其规则/误报豁免/输出 schema）。
- **子 Agent 约束**：
  - 只读；可 `git show`/`git blame` 辅助判断上下文。
  - **禁止** `git add/commit/checkout/reset/push` 等任何写操作。
  - **禁止**写任何文件；审查结果只在回复中以 JSON 返回（schema 见指令文件）。
  - 不修改被测代码。
- **结果收集**：子 Agent 返回 findings JSON 后，存为 `findings.json`，交给步骤 C 的 `assemble`。

---

## 报告格式

`go-secret-leak-report.json`：

```json
{
  "skill": "go-secret-leak-review",
  "mode": "incremental",
  "repo": "/path/to/repo",
  "commit_range": "<A>..<B>",
  "generated_at": "2026-07-16T11:30:00.000",
  "summary": {"total_findings": 2, "by_level": {"L1": 0, "L2": 0, "L3": 0, "L4": 2}, "by_confidence": {"high": 2, "medium": 0, "low": 0}},
  "findings": [
    {
      "file": "internal/auth/login.go",
      "line": 42,
      "level": "L4",
      "confidence": "high",
      "indirect": false,
      "evidence": "log.Printf(\"pwd=%s\", password)",
      "reason": "password 变量值被直接打印到日志",
      "suggestion": "移除日志输出，或将值替换为 [REDACTED]"
    },
    {
      "file": "internal/auth/login.go",
      "line": 58,
      "level": "L4",
      "confidence": "high",
      "indirect": true,
      "leak_path": "User.Password -> json.Marshal(u) -> log.Printf(\"user=%s\", b)",
      "evidence": "b, _ := json.Marshal(u); log.Printf(\"user=%s\", b)",
      "reason": "User 含 Password 字段（json:\"password\"，非 \"-\"），整体序列化后打印，等效泄露密码",
      "suggestion": "Password 字段加 `json:\"-\"` 标签，或实现 MarshalJSON() 对敏感字段脱敏"
    }
  ]
}
```

- `level`：`L1` / `L2` / `L3` / `L4`，取值依据 `references/secret-leak-review-prompt.md` 的「敏感数据分级」表（如密码→L4、身份证→L3、手机号/姓名→L2）。间接泄露按**被泄露最敏感字段**的 level 定级。
- `confidence`：`high` / `medium` / `low`，表示判定置信度（可能因误报而偏低）。`low`/`medium` 的 finding 建议人工复核后再处置。
- `summary.by_level`：按 L1–L4 的分布计数。
- `summary.by_confidence`：按 high/medium/low 的分布计数。
- `indirect`：`true` 表示间接泄露（结构体/容器整体序列化打印），此时 `leak_path` 描述从敏感字段到日志出口的链路；省略或 `false` 表示直接打印标量值。
- `mode`：`incremental`（增量）/ `single`（单 commit）/ `full`（全量扫描）。
- `commit_range`：增量模式为 `<A>..<B>`；单 commit 模式为 `<commit>^(单 commit)`；全量模式为 `FULL(全量扫描)`。
- 空区间或无命中 → `findings: []`，`summary` 全 0。

---

## 误报豁免（子 Agent 据此降噪）

命中下列任一条不报：变量名含 `mock/dummy/example/fake/test`、已做掩码（`Mask()`/`****`/仅打印前几位）、打印的是字段名/类型名常量而非值、Debug 级演示字面量、单测对字面量的断言、仅打印 `len()`/`Contains()` 等元信息。

---

## 关键约束（硬）

- `$SKILL_DIR` 仅读（脚本/指令）；所有产出只写 `$REPO_ROOT`，**绝不**写 `$SKILL_DIR`/`$HOME`/`~/.codebuddy`/`/tmp`。
- **禁止** `git add` / `git commit`；变更留给用户审阅后自行提交。
- 只读分析，不修改被测代码。

---

## 文件结构

```
go-secret-leak-review/
├── SKILL.md                              # 本文件
├── README.md                             # 用法 + 示例
├── scripts/
│   ├── extract_diff.sh                   # 只读抽取 commitA..commitB 增量 diff
│   └── review_secret_leak.py             # 主入口：extract / assemble 两模式
└── references/
    └── secret-leak-review-prompt.md      # 子 Agent 审查指令（规则 + 误报豁免 + 输出 schema）
```

**维护者**: go-secret-leak-review 团队  
**许可证**: MIT
