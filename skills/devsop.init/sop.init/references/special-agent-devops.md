# DevOps 梳理子 Agent 指令

> 本文件作为 `devops` 梳理子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/devops/`（环境搭建 + 测试环境部署 + 发布规范区）。

---

## 核心目标

基于项目真实构建 / 部署 / 环境配置，把 `.harness/docs/devops/` 充实为可落地的运维文档集。

---

## 步骤

### 1. 扫描运维事实

从信息源抽取（**禁止凭记忆编造**）：
- `Makefile` / `package.json scripts` / `Cargo.toml` → 构建 / 测试 / lint 命令
- `Dockerfile` / `docker-compose*.yaml` → 镜像构建、端口、卷
- K8s / Helm / deploy 目录 → 部署拓扑、环境分层
- `.github/workflows/` / `Jenkinsfile` / `.gitlab-ci.yml` → CI 流程
- 配置文件（env / yaml / toml）→ 环境变量、配置分层
- 测试环境工具（如团队环境管理 CLI / 团队环境管理 Skill）→ 环境就绪检查 + 部署同步流程

### 2. 生成文档

按 skeleton 章节填充：
- `devops/env.md` —— 本地开发环境搭建、依赖安装、一键运行、常见问题
- `devops/deployment.md` —— 部署与运行规范（环境矩阵 / 制品 / 配置 / 发布 / 回滚）
- `devops/development.md` —— 本地开发环境规范（依赖 / 一键运行 / IDE / FAQ）
- `devops/test-env-deploy.md` —— **按章节分治**：`## 项目自定义` 之上为 skill 管控区（环境管理 CLI 工具就绪检查 + 团队环境管理 Skill / 团队测试工具 Skill 操作说明），之下为项目自定义区（组件清单 / 常用环境 / 特殊同步规则）**保留用户内容不改不删**。

### 3. 实跑验证（如可行）

对文档中的构建 / 测试 / 启动命令，本地实跑一遍确认命令可用；不可跑（无环境 / 需权限）则在文档标注 `<!-- TODO(sop.init): 命令待实跑验证 -->`。

---

## 约束

- `test-env-deploy.md` 的项目自定义区是用户资产，**仅刷新 skill 管控区**，严禁整篇覆盖。
- 命令必须来自实际 Makefile / CI / Dockerfile，禁止臆造。
- 只动 `devops/` 下文件，不动其它 docs。
