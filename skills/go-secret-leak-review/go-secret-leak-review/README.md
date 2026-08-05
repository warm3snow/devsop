# go-secret-leak-review Skill

**增量代码隐私泄露专项审查器** —— 检测密码 / 私钥 / Token / 凭证被打印到日志或标准输出的风险。

## 解决的问题

开发时容易把敏感值打进日志：

```go
log.Printf("user login pwd=%s", password)     // ❌ 密码泄露
fmt.Println("private key:", privateKeyPEM)     // ❌ 私钥泄露
zap.S().Infof("token=%s", accessToken)        // ❌ Token 泄露
```

本 skill 对指定 `commitA..commitB` 区间的**增量代码**做专项 Code Review，通过子 Agent 定位泄露的 `文件:行`。

## 前置依赖

仅依赖 `git`（系统自带），无需额外安装工具。

## 使用流程

```bash
SKILL_DIR=skills/go-secret-leak-review

# 步骤 A：抽取增量 diff（写 REPO_ROOT 下 go-secret-leak-diff.txt）
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitA> <commitB> [--path=subdir] [--out=diff.txt]

# 步骤 B：调用方（CodeBuddy）派发子 Agent
#   指令文件：$SKILL_DIR/references/secret-leak-review-prompt.md
#   输入：REPO_ROOT + 步骤 A 的 diff 文本
#   约束：只读、禁 git 写、禁写文件；返回 findings JSON

# 步骤 C：汇总为最终报告（写 REPO_ROOT 下 go-secret-leak-report.json）
python3 $SKILL_DIR/scripts/review_secret_leak.py assemble \
    /path/to/repo <commitA> <commitB> --findings=findings.json [--out=report.json]
```

### 区间语义

`git diff commitA commitB` = **commitB 相对 commitA 的变更**（commitA 不含，commitB 含）。两 commit 相同 → 空区间，步骤 A 直接产出「无增量」报告。

## 报告字段

`go-secret-leak-report.json`：

| 字段                       | 说明                                                          |
| -------------------------- | ------------------------------------------------------------- |
| `commit_range`           | `<A>..<B>`                                                  |
| `summary.total_findings` | 命中总数                                                      |
| `summary.by_level`       | 按 L1–L4 的分布计数                                          |
| `summary.by_confidence`  | 按 high/medium/low 的分布计数                                 |
| `findings[].file`        | 相对仓库路径                                                  |
| `findings[].line`        | diff 目标行号                                                 |
| `findings[].level`       | `L1` / `L2` / `L3` / `L4`（敏感数据级别）             |
| `findings[].confidence`  | `high` / `medium` / `low`（判定置信度，可能因误报偏低） |
| `findings[].evidence`    | 命中的代码行原文                                              |
| `findings[].reason`      | 判定泄露的依据                                                |
| `findings[].suggestion`  | 脱敏 / 掩码 / 移除日志 等建议                                 |

## 检测范围与误报豁免

**检测**：密码、私钥/证书、Token/API Key/SecretKey、含口令的数据库连接串、Authorization 头原始值、PII（身份证/银行卡/护照，手机号/邮箱/姓名/IP/微信号/QQ）。

**豁免**（不报）：变量名含 `mock/dummy/example/fake/test`、已做掩码（`Mask()`/`****`/仅打印前几位）、打印的是字段名/类型名常量而非值、Debug 级演示字面量、单测对字面量的断言、仅打印 `len()`/`Contains()` 等元信息。

## 约束

- 只读分析，不修改被测代码。
- 产出只写 `REPO_ROOT`，绝不写 `$SKILL_DIR`/`$HOME`/`/tmp`。
- 禁止 `git add`/`git commit`，变更由用户审阅后自行提交。

## 与 go-quality-scorer 的关系

独立、互补：`go-quality-scorer` 做六维全量评分（含 D2 安全红线），本 skill 专注「增量代码里的隐私日志泄露」这一高频高危场景，审查更聚焦、可对准 commit 区间。

## 版本

| 版本  | 日期       | 说明                                                                                                                                                     |
| ----- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.1.0 | 2026-07-22 | 新增间接泄露检测（结构体/容器整体序列化打印）；对齐 L0–L4 敏感数据分级；报告增加 level（L1–L4）+ confidence 置信度，移除 severity 与 category 冗余维度 |
| 1.0.0 | 2026-07-16 | 初始发布：增量 diff 抽取 + 子 Agent 隐私泄露审查                                                                                                         |

> 敏感数据分级（L0–L4）与脱敏规范的唯一权威来源见 `references/secret-leak-review-prompt.md`。

**许可证**: MIT
