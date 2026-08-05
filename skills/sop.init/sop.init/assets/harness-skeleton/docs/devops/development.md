# 本地开发环境规范

> 状态：草稿 | 维护者：{{姓名}} | 最后更新：{{YYYY-MM-DD}}

## 范围

新人 30 分钟内跑通本服务的最低要求。所有命令必须经过验证。

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | {{macOS / Linux / Windows + WSL2}} |
| 内存 | ≥{{8GB}} |
| 磁盘 | ≥{{20GB}} 空闲 |

## 必装依赖

```bash
# 1. 语言运行时
{{安装命令，含具体版本，例如 go1.24.12 必装}}

# 2. 数据库 / 中间件（推荐 Docker 起）
{{docker-compose up -d 或 brew install ...}}

# 3. 开发工具
{{make tools 或逐个安装命令}}
```

**版本一致性**：本仓库锁定 {{语言版本}}，禁用其他版本（CI 与本地必须一致，否则编译/测试结果可能不可重现）。

## 仓库初始化

```bash
git clone {{repo-url}}
cd {{repo-name}}
{{初始化命令：依赖安装、生成代码、初始化数据库}}
```

## 一键运行

```bash
{{make dev / make run / 等效命令}}
```

预期输出：{{监听端口、启动日志关键行}}

## 常用 make 目标

| 命令 | 用途 |
|------|------|
| `make build` | 编译产物 |
| `make lint` | 静态检查 |
| `make ut` | 单元测试 |
| `make integration-test` | 集成测试 |
| `make gen` | 从 IDL 生成代码 |
| `make mock` | 重新生成 mock |
| `make tools` | 安装开发工具 |
| `make init-db` | 初始化数据库 |

完整清单：`make help` 或 `Makefile`。

## IDE 推荐配置

- {{IDE 名称}}
- 插件：{{Go / ESLint / Prettier 等}}
- 配置：{{`.editorconfig` / 推荐设置}}

## 调试

- 启动：{{IDE Run/Debug 配置 或 dlv 命令}}
- 远程调试端口：{{2345}}
- 日志位置：{{logs/ 路径}}

## 常见问题（FAQ）

- **Q: `make build` 报版本错误？** A: 检查 `go version`，必须为 {{版本}}
- **Q: 端口被占用？** A: {{解决方式}}
- **Q: 数据库连不上？** A: {{解决方式}}

更多踩坑见 [failures.md](failures.md)。

## CI/CD 与交付

### CI/CD 流水线

> 如项目未接入 CI/CD，可删除本节。

- 平台：{{Jenkins / GitLab CI / GitHub Actions / 其他}}
- 流水线配置文件：`{{.gitlab-ci.yml / .github/workflows/ci.yaml / Jenkinsfile}}`
- 触发方式：{{push / MR / tag / 手动}}

流水线流程：

```mermaid
graph LR
    A[{{触发条件}}] --> B[{{阶段1}}]
    B --> C[{{阶段2}}]
    C --> D[{{阶段3}}]
    D --> E[{{阶段N...按实际流水线补充}}]
```

> 按实际流水线修改上图，保留 mermaid 格式便于渲染。

### Helm 包

> 如项目未使用 Helm，可删除本节。

| 项目 | 说明 |
|------|------|
| Helm Chart 仓库 | `{{仓库地址}}` |
| Chart 路径 | `{{deploy/helm/chart-name/}}` |

Chart 目录结构：

```
{{chart-path}}/
├── Chart.yaml      # Chart 元信息（name / version / appVersion）
├── values.yaml     # 默认 values
├── templates/      # K8s 资源模板
│   └── ...
└── {{其他文件按项目实际补充}}
```

> 按项目实际 Chart 内容补充目录结构与关键 values 字段说明。

## 参考

- 项目介绍：[../README.md](../README.md)
- AI 协作入口：[../AGENTS.md](../AGENTS.md)
