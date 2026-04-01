# 代码架构摘要
## 项目：/Users/me/work/saas-platform
## 分析时间：2026-03-31

---

## 目录结构

```
saas-platform/
├── apps/
│   ├── web/                    # Next.js 14 前端应用
│   │   ├── app/               # App Router
│   │   │   ├── (auth)/       # 认证相关路由组
│   │   │   ├── (dashboard)/  # 仪表板路由组
│   │   │   ├── api/          # Next.js API Routes
│   │   │   └── layout.tsx
│   │   ├── components/        # React 组件
│   │   │   ├── ui/           # 基础 UI 组件
│   │   │   ├── editor/       # 富文本编辑器组件
│   │   │   └── agents/       # Agent 相关组件
│   │   ├── lib/              # 前端工具函数
│   │   │   ├── utils.ts
│   │   │   ├── api.ts        # tRPC 客户端
│   │   │   └── websocket.ts  # WebSocket 连接
│   │   └── package.json
│   └── api/                   # tRPC 后端服务
│       ├── src/
│       │   ├── router/       # tRPC 路由
│       │   │   ├── auth.ts
│       │   │   ├── tenants.ts
│       │   │   ├── documents.ts
│       │   │   └── agents.ts
│       │   ├── middleware/   # 中间件
│       │   │   ├── auth.ts
│       │   │   └── tenant.ts # 多租户 schema 切换
│       │   ├── lib/          # 后端工具函数
│       │   │   ├── db.ts     # Prisma 客户端
│       │   │   ├── redis.ts
│       │   │   └── agents/   # Agent 执行引擎
│       │   └── index.ts      # tRPC 服务器入口
│       └── package.json
├── packages/
│   ├── shared/               # 共享类型和工具
│   │   ├── src/
│   │   │   ├── types/       # TypeScript 类型定义
│   │   │   ├── utils/       # 共享工具函数
│   │   │   └── constants.ts
│   │   └── package.json
│   ├── database/            # Prisma schema 和客户端
│   │   ├── prisma/
│   │   │   └── schema.prisma
│   │   └── package.json
│   └── yjs-sync/            # Yjs 同步服务
│       ├── src/
│       │   ├── server.ts    # WebSocket 服务器
│       │   └── sync-handler.ts
│       └── package.json
├── tool-agents/             # AI Agent 工具定义
│   ├── src/
│   │   ├── tools/          # 工具注册表
│   │   │   ├── web-search.ts
│   │   │   ├── calculator.ts
│   │   │   └── file-operations.ts
│   │   └── agent-executor.ts
│   └── package.json
├── turbo.json              # Turborepo 配置
├── package.json           # 根 package.json
├── docker-compose.yml     # 开发环境 Docker
└── README.md
```

---

## 技术栈与依赖

### 核心依赖
- **Monorepo 工具**: Turborepo
- **前端框架**: Next.js 14 (App Router), React 18, TypeScript
- **样式方案**: Tailwind CSS
- **状态管理**: Zustand (局部状态) + React Query (服务器状态)
- **API 通信**: tRPC (类型安全 RPC)
- **数据库 ORM**: Prisma
- **数据库**: PostgreSQL (开发环境用 Docker)
- **缓存**: Redis (用于会话和实时同步)
- **实时通信**: WebSocket (ws 库) + Yjs (CRDT)
- **AI/LLM**: OpenAI API (gpt-4), Anthropic Claude API
- **测试**: Vitest (单元), Playwright (E2E)
- **部署**: Vercel (前端), Railway (后端), Supabase (数据库)

### package.json 关键依赖
```json
{
  "dependencies": {
    "next": "14.x",
    "react": "18.x",
    "typescript": "5.x",
    "prisma": "5.x",
    "@trpc/server": "10.x",
    "@trpc/client": "10.x",
    "@trpc/react-query": "10.x",
    "zod": "3.x",
    "zustand": "4.x",
    "@tanstack/react-query": "5.x",
    "yjs": "13.x",
    "y-websocket": "1.x",
    "redis": "4.x",
    "openai": "4.x",
    "@anthropic-ai/sdk": "0.x"
  },
  "devDependencies": {
    "turbo": "1.x",
    "vitest": "1.x",
    "playwright": "1.x",
    "@types/node": "20.x"
  }
}
```

---

## 数据库 Schema (Prisma)

### 核心模型
```prisma
model Tenant {
  id        String   @id @default(cuid())
  name      String
  slug      String   @unique
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // 多租户：每个租户有自己的 schema
  users     User[]
  documents Document[]
  agents    Agent[]
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id])
  role      Role     @default(USER)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Document {
  id        String   @id @default(cuid())
  title     String
  content   Json     // Yjs 文档状态
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id])
  version   Int      @default(1)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Agent {
  id        String   @id @default(cuid())
  name      String
  config    Json     // Agent 配置（工具列表、提示词等）
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id])

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

---

## Git 提交历史分析

### 最近关键提交
1. **feat: 实现多租户中间件** (3天前)
   - 添加 tenant.middleware.ts，根据请求头切换 PostgreSQL schema
   - 实现租户识别逻辑（子域名或 API key）

2. **feat: 集成 Yjs 实时协作** (5天前)
   - 添加 yjs-sync 包，WebSocket 服务器
   - 前端集成 Yjs Provider，文档同步

3. **feat: Agent 工具注册表** (7天前)
   - 实现 ToolRegistry 类，支持动态注册工具
   - 添加 web-search、calculator 等基础工具

4. **chore: 配置 Turborepo 缓存** (10天前)
   - 优化 turbo.json 配置，启用远程缓存
   - 配置环境变量管理

5. **fix: 修复 tRPC 类型导出** (12天前)
   - 解决 shared 包类型导出问题
   - 更新客户端类型安全调用

### 代码统计
- 总文件数：287
- TypeScript 文件：243
- 测试文件：34
- 配置文件：10
- 总代码行数：~15,000

---

## 架构模式识别

### 1. 分层架构
- **表现层**: Next.js App Router + React 组件
- **应用层**: tRPC 路由 + 业务逻辑
- **领域层**: Prisma 模型 + 领域服务
- **基础设施层**: 数据库、Redis、外部 API

### 2. 多租户模式
- Schema 隔离策略
- 中间件动态切换数据库上下文
- 租户识别（子域名 / API key）

### 3. 实时协作架构
- CRDT (Yjs) 解决冲突
- WebSocket 双向通信
- Redis Pub/Sub 广播消息

### 4. AI Agent 架构
- 工具模式（Tool Pattern）
- 执行引擎（AgentExecutor）
- 记忆管理（短期/长期）

---

## 代码质量指标

### 测试覆盖率
- 单元测试：~65% (主要覆盖工具函数和组件逻辑)
- 集成测试：~40% (API 路由和数据库交互)
- E2E 测试：~25% (关键用户流程)

### 类型安全
- TypeScript 严格模式启用
- tRPC 提供端到端类型安全
- Zod 用于运行时验证

### 代码规范
- ESLint + Prettier 配置
- Husky 预提交钩子
- 提交信息规范（Conventional Commits）

---

## 发现与观察

### Session 与代码一致性
1. **高度一致**：
   - Monorepo 结构（Turborepo）✅
   - 技术栈选型（Next.js 14 + Prisma + tRPC）✅
   - 多租户 schema 隔离 ✅
   - Yjs 实时协作 ✅

2. **部分实现**：
   - Agent 工具注册表已实现，但记忆管理未完成
   - 测试策略有基础配置，但覆盖率不足

3. **未实现**：
   - 监控与日志系统（Session 讨论但代码无实现）
   - 移动端 PWA 支持（未讨论也未实现）
   - 高级安全特性（RBAC、审计日志）

### 架构成熟度
- **基础架构**：稳固（monorepo、类型安全、数据库）
- **核心功能**：实现中（多租户、实时协作、Agent）
- **生产就绪**：待完善（监控、安全、性能优化）