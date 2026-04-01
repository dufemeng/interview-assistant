# 代码架构摘要 - Video Script Agent

## 项目基本信息
- **项目路径**: ~/projects/video-script-agent
- **仓库类型**: Git
- **主要语言**: TypeScript (85%), JavaScript (10%), Other (5%)
- **代码行数**: ~12,000 行
- **提交数量**: 47 commits
- **开发周期**: 2026-02-10 至 2026-03-30

## 目录结构
```
video-script-agent/
├── packages/
│   ├── backend/                    # NestJS 后端
│   │   ├── src/
│   │   │   ├── modules/
│   │   │   │   ├── agent/          # Agent 核心模块
│   │   │   │   │   ├── agents/     # 各个 Agent 实现
│   │   │   │   │   │   ├── topic-analyzer.agent.ts
│   │   │   │   │   │   ├── structure-planner.agent.ts
│   │   │   │   │   │   ├── dialogue-generator.agent.ts
│   │   │   │   │   │   └── shot-suggester.agent.ts
│   │   │   │   │   ├── tools/      # Agent 工具定义
│   │   │   │   │   ├── chains/     # LangChain 链定义
│   │   │   │   │   └── prompts/    # System prompt 模板
│   │   │   │   ├── queue/          # BullMQ 队列模块
│   │   │   │   │   ├── processors/ # 任务处理器
│   │   │   │   │   ├── workers/    # Worker 定义
│   │   │   │   │   └── jobs/       # Job 类型定义
│   │   │   │   ├── cache/          # 缓存模块 (Redis)
│   │   │   │   ├── database/       # 数据库模块 (PostgreSQL + Prisma)
│   │   │   │   └── websocket/      # WebSocket 模块
│   │   │   ├── config/             # 配置管理
│   │   │   └── common/             # 公共工具
│   │   ├── test/                   # 测试文件
│   │   └── package.json
│   ├── frontend/                   # React 前端
│   │   ├── src/
│   │   │   ├── features/
│   │   │   │   ├── script-generator/ # 脚本生成页面
│   │   │   │   ├── script-history/   # 历史记录
│   │   │   │   └── settings/         # 设置页面
│   │   │   ├── components/           # 公共组件
│   │   │   ├── hooks/                # 自定义 Hook
│   │   │   ├── stores/               # Zustand 状态管理
│   │   │   └── api/                  # API 客户端
│   │   └── package.json
│   └── shared/                     # 共享代码
│       └── types/                  # TypeScript 类型定义
├── docker-compose.yml              # 开发环境配置
├── Dockerfile                      # 生产环境镜像
├── package.json                    # 根目录 package.json (workspace)
└── README.md
```

## 依赖栈分析

### 后端依赖 (packages/backend)
```json
{
  "核心框架": ["@nestjs/common", "@nestjs/core", "@nestjs/platform-express"],
  "数据库": ["@prisma/client", "prisma"],
  "队列": ["bullmq", "ioredis"],
  "LLM集成": ["langchain", "@langchain/openai", "@langchain/community"],
  "工具库": ["axios", "lodash", "dayjs", "class-validator", "class-transformer"],
  "开发依赖": ["@nestjs/testing", "jest", "supertest", "@types/jest"]
}
```

### 前端依赖 (packages/frontend)
```json
{
  "核心框架": ["react", "react-dom"],
  "状态管理": ["zustand", "@tanstack/react-query"],
  "UI库": ["@radix-ui/react-dialog", "@radix-ui/react-dropdown-menu"],
  "样式": ["tailwindcss", "postcss", "autoprefixer"],
  "工具库": ["axios", "dayjs", "lodash"],
  "开发依赖": ["@types/react", "@types/react-dom", "vite", "typescript"]
}
```

## 架构模式识别

### 1. 微服务架构特征
- **模块化设计**: 后端按功能拆分为独立 NestJS 模块
- **清晰边界**: Agent 模块、队列模块、缓存模块职责分离
- **API 网关模式**: 统一的 REST API 入口，内部模块间通过服务类调用

### 2. 事件驱动架构
- **BullMQ 队列**: 用于异步任务处理
- **WebSocket 推送**: 实时任务状态更新
- **Redis Pub/Sub**: 模块间事件通信（代码中发现使用痕迹）

### 3. 分层架构
- **表现层**: REST API + WebSocket
- **业务逻辑层**: Agent 服务 + 队列处理器
- **数据访问层**: Prisma ORM + Redis 客户端
- **基础设施层**: 配置管理、日志、监控

## 核心模块实现分析

### Agent 模块 (packages/backend/src/modules/agent/)
- **实现状态**: 🟢 完整实现
- **关键文件**:
  - `agent.service.ts`: Agent 编排服务，管理多步骤工作流
  - `agents/*.agent.ts`: 4个专用 Agent 实现
  - `chains/script-generation.chain.ts`: LangChain 链定义
- **技术特点**:
  - 使用 LangChain 的 `RunnableSequence` 串联多个 Agent
  - 每个 Agent 有独立的 system prompt 和工具集
  - 支持流式输出（Server-Sent Events）

### 队列模块 (packages/backend/src/modules/queue/)
- **实现状态**: 🟢 完整实现
- **关键文件**:
  - `queue.service.ts`: BullMQ 队列管理服务
  - `processors/script-generation.processor.ts`: 脚本生成任务处理器
  - `workers/main.worker.ts`: 主 Worker 进程
- **技术特点**:
  - 使用 Redis 作为队列存储
  - 支持任务优先级和延迟执行
  - 实现自动重试和失败处理

### 缓存模块 (packages/backend/src/modules/cache/)
- **实现状态**: 🟡 部分实现
- **关键文件**:
  - `cache.service.ts`: Redis 缓存服务
  - `strategies/script-cache.strategy.ts`: 脚本缓存策略
- **技术特点**:
  - 二级缓存策略（内存 + Redis）
  - 基于语义相似度的缓存键生成
  - TTL 配置可动态调整

### 前端架构 (packages/frontend/)
- **实现状态**: 🟢 完整实现
- **关键特点**:
  - 使用 TanStack Query 处理数据获取和缓存
  - Zustand 管理客户端状态
  - WebSocket 实时连接任务状态
  - 响应式设计，支持移动端

## Git 提交历史分析

### 主要开发阶段
1. **2026-02-10 至 2026-02-20**: 基础架构搭建
   - 初始化 NestJS + React 项目
   - 配置 Docker 开发环境
   - 实现基础 API 和数据库模型

2. **2026-02-21 至 2026-03-05**: Agent 核心功能
   - 集成 LangChain.js
   - 实现多步骤 Agent 工作流
   - 添加 BullMQ 任务队列

3. **2026-03-06 至 2026-03-20**: 前端实现
   - 构建 React 前端界面
   - 实现实时进度展示
   - 添加脚本历史管理

4. **2026-03-21 至 2026-03-30**: 优化和部署
   - 添加缓存层
   - 优化错误处理
   - 配置 CI/CD 流水线

### 关键提交
- `feat: implement multi-agent workflow with LangChain` (2026-02-25)
- `feat: add BullMQ queue for async task processing` (2026-02-28)
- `feat: real-time progress with WebSocket` (2026-03-10)
- `perf: add Redis cache for script generation` (2026-03-25)

## 代码质量指标

### 测试覆盖率
- **后端**: 68% (单元测试 + 集成测试)
- **前端**: 45% (组件测试 + E2E 测试)
- **核心模块**: Agent 模块 85%，队列模块 75%

### 代码规范
- **TypeScript 严格模式**: 启用
- **ESLint 配置**: Airbnb 规范 + 自定义规则
- **Prettier**: 代码格式化
- **Husky**: Git 提交前检查

### 文档完整性
- **API 文档**: Swagger/OpenAPI 自动生成
- **架构文档**: README.md + ARCHITECTURE.md
- **部署文档**: DEPLOYMENT.md
- **开发指南**: CONTRIBUTING.md

## 架构决策验证

### Session 提及且代码实现的决策
1. ✅ NestJS + BullMQ + LangChain.js 技术栈
2. ✅ 多步骤 Agent 工作流（4个专用 Agent）
3. ✅ 任务队列 + WebSocket 实时状态
4. ✅ Redis 缓存层
5. ✅ React + TypeScript 前端

### Session 提及但代码未完全实现的决策
1. 🔴 A/B 测试框架（仅预留接口，未实现）
2. 🔴 用户行为分析（数据库有表结构，无数据收集逻辑）
3. 🔴 多语言支持（仅中文处理，无国际化配置）

### 代码实现但 Session 未提及的细节
1. 🔵 使用 Prisma ORM 而非 TypeORM（Session 未讨论 ORM 选型）
2. 🔵 实现基于语义相似度的缓存键生成（Session 只提到缓存，未提及具体算法）
3. 🔵 前端使用 Radix UI 组件库（Session 只提到 React，未提及具体 UI 库）