# scripts/ — 职责说明

本目录是 devsop 仓库自身的工具与 Git Hook 入口。分工如下：

| 脚本 | 功能 | 运行时机 | 使用者 |
|------|------|----------|--------|
| `validate_skills.sh` | 校验技能库是否合规（frontmatter / 命名 / 行数 / 引用深度 / 脚本语法） | 手动或 CI（`--json`） | 技能库维护者（**本仓库专用**，不随 devsop-init 分发到目标项目） |
| `pre_commit_check.sh` | 检查暂存区空白错误和冲突标记（`git diff --cached --check`） | git pre-commit hook | 本仓库 + 所有 devsop-init 初始化的项目 |
| `commit_msg_check.sh` | 检查 `<type>(<module-or-service>): <subject>` 标题（仅允许 `feat` / `fix` / `docs` / `refactor`） | git commit-msg hook | 同上 |

> 说明：2 个 hook 脚本是软链，指向 `skills/devsop-init/scripts/`（单一来源）。初始化时仅复制这两个脚本到目标项目的 `scripts/` 目录；不会安装 pre-push，也不会覆盖已有脚本或 hook。`validate_skills.sh` 只服务于本技能库，不复制。

## 常用命令

```bash
# 校验技能库（汇总 + 违规项）
bash scripts/validate_skills.sh

# 逐项明细 / 严格模式（警告也算失败）/ CI 机器可读
bash scripts/validate_skills.sh -v
bash scripts/validate_skills.sh --strict
bash scripts/validate_skills.sh --json

# 本仓库提交前的完整检查（含钩子脚本）
bash scripts/validate_skills.sh --strict
bash scripts/pre_commit_check.sh
bash scripts/commit_msg_check.sh
```
