# 项目知识图谱
## 项目：SaaS 平台 (Turborepo + Next.js 14 + Prisma + tRPC + AI Agent)
## 生成时间：2026-03-31
## 数据源：extracted_decisions.md + code_summary.md

---

## 1. 技术栈与架构模式

### 核心技术栈
| 技术 | Session 讨论 | 代码实现 | 说明 |
|------|--------------|----------|------|
| **Turborepo** | ✅ 明确讨论选型理由（vs Lerna/Nx） | ✅ packages/ 目录结构，turbo.json 配置 | 选择理由：轻量、Vercel 生态集成好、缓存机制优秀 |
| **Next.js 14** | ✅ App Router 优势讨论 | ✅ apps/web/ 使用 App Router | 选择理由：服务端组件、文件路由、Vercel 优化 |
| **Prisma** | ✅ 多租户方案详细讨论 | ✅ packages/database/ schema.prisma | 选择理由：类型安全、迁移管理简单、多租户支持 |
| **tRPC** | ✅ 类型安全 API 讨论 | ✅ apps/api/ tRPC 路由配置 | 选择理由：端到端类型安全、开发体验好 |
| **PostgreSQL** | ✅ Schema 隔离方案 | ✅ Docker Compose 配置，Prisma 模型 | 多租户：schema 隔离而非物理数据库分离 |
| **Yjs** | ✅ CRDT vs OT 技术选型 | ✅ packages/yjs-sync/ WebSocket 服务器 | 选择理由：无冲突数据类型、离线同步能力 |
| **Redis** | ✅ 会话缓存和实时广播 | ✅ apps/api/lib/redis.ts | 用途：WebSocket 会话管理、Pub/Sub 广播 |
| **OpenAI/Claude** | ✅ Agent 集成讨论 | ✅ tool-agents/ 包集成 | LLM 调用：工具调用决策、内容生成 |

### 架构模式
- **Monorepo 架构**：Turborepo 管理多个包（前端、后端、共享代码）
- **前后端分离**：Next.js 前端 + tRPC 后端，共享 TypeScript 类型
- **多租户架构**：PostgreSQL schema 隔离，中间件动态切换
- **实时协作架构**：CRDT (Yjs) + WebSocket + Redis Pub/Sub
- **AI Agent 架构**：工具模式 + 执行引擎 + 记忆管理

---

## 2. 关键架构决策清单

### 决策 1：Monorepo 工具选型（Turborepo vs Lerna/Nx）
- **决策描述**：选择 Turborepo 作为 monorepo 管理工具，而非 Lerna 或 Nx
- **背景**：项目需要管理多个包（前端、后端、共享类型、Agent 工具），需要高效的依赖管理和构建缓存
- **取舍**：
  - 选择 Turborepo：轻量、Vercel 生态集成好、缓存机制对开发体验提升明显
  - 放弃 Lerna：维护状态一般，功能相对基础
  - 放弃 Nx：功能强大但学习曲线陡峭，配置复杂
- **置信度**：🟢 高（Session 详细讨论 + 代码完整实现）

### 决策 2：多租户数据库方案（Schema 隔离 vs 物理分离）
- **决策描述**：使用 PostgreSQL schema 隔离实现多租户，而非每个租户独立数据库
- **背景**：SaaS 平台需要数据隔离，初期租户数量少但需要快速验证业务模型
- **取舍**：
  - 选择 Schema 隔离：迁移管理简单、连接池复用、备份恢复统一
  - 放弃物理分离：初期运维复杂、连接管理困难
  - 保留扩展性：大租户可后期迁移到独立数据库（分片策略）
- **置信度**：🟢 高（Session 技术讨论 + 代码 tenant.middleware.ts 实现）

### 决策 3：实时协作技术选型（Yjs CRDT vs Operational Transformation）
- **决策描述**：选择 Yjs（CRDT）实现实时文档协作，而非 Operational Transformation（OT）
- **背景**：需要类似 Google Docs 的实时协作体验，支持离线编辑和冲突解决
- **取舍**：
  - 选择 Yjs CRDT：无冲突数据类型、去中心化、离线同步能力强
  - 放弃 OT：需要中央服务器解决冲突、实现复杂、状态同步困难
  - 架构：前端 Yjs 维护文档状态，WebSocket 同步，Redis Pub/Sub 广播
- **置信度**：🟢 高（Session 技术对比 + packages/yjs-sync/ 实现）

### 决策 4：AI Agent 架构设计（工具模式 + 执行引擎）
- **决策描述**：设计 Agent 架构包含工具注册表、执行引擎、记忆管理三层
- **背景**：平台需要集成 AI Agent 能力，能够调用外部工具并保持会话状态
- **取舍**：
  - 架构选择：工具模式（灵活扩展）而非硬编码 Agent 逻辑
  - 状态管理：Redis（短期会话）+ PostgreSQL（长期记忆）
  - LLM 集成：支持多模型（OpenAI + Claude），可配置
- **置信度**：🟡 中（Session 详细讨论 + 部分代码实现，记忆管理未完成）

### 决策 5：部署策略（Vercel + Railway + 托管数据库）
- **决策描述**：选择 Vercel（前端）+ Railway（后端）+ Supabase/Neon（数据库）的托管部署方案
- **背景**：团队规模小，需要快速部署和运维简化，同时保证可扩展性
- **取舍**：
  - 选择托管服务：降低运维负担、自动 CI/CD、弹性扩展
  - 放弃自建 K8s：初期运维复杂、成本高
  - 环境管理：dotenv + Turborepo 环境配置
- **置信度**：🟡 中（Session 详细讨论 + docker-compose.yml 配置，但生产部署配置未在代码中体现）

### 决策 6：测试策略分层（单元 + 集成 + E2E + LLM Mock）
- **决策描述**：实施分层测试策略：单元测试（工具函数）、集成测试（API+DB）、E2E测试（用户流）、LLM Mock（Agent测试）
- **背景**：项目复杂度高，需要保证多租户、实时协作、AI Agent 的可靠性
- **取舍**：
  - 测试框架：Vitest（单元） + Playwright（集成/E2E）
  - LLM 测试：Mock 响应 + 录制回放模式
  - 测试并行：Turborepo 缓存加速测试运行
- **置信度**：🟡 中（Session 讨论 + 基础测试配置，但覆盖率不足）

---

## 3. 交叉印证发现

### Gap（说了没做）
1. **监控与日志系统**
   - Session 提到需要监控但未讨论具体方案
   - 代码中无 Prometheus/Grafana 或日志聚合实现
   - 影响：生产环境可观测性不足

2. **安全审计功能**
   - Session 未深入讨论 API 安全、数据加密、权限验证细节
   - 代码中只有基础 JWT 认证，无审计日志或高级 RBAC
   - 影响：企业级安全要求未满足

3. **性能优化缓存**
   - Session 提到缓存但未具体实现方案
   - 代码中 Redis 仅用于会话，无查询缓存或 CDN 配置
   - 影响：高并发场景性能可能不足

### 孤岛（做了没说）
1. **共享类型包（packages/shared/）**
   - Session 未详细讨论类型共享设计
   - 代码中已实现完整的共享类型系统
   - 价值：保证前后端类型安全的关键架构

2. **Docker Compose 开发环境**
   - Session 未讨论本地开发环境配置
   - 代码中有完整的 docker-compose.yml（PostgreSQL + Redis）
   - 价值：团队 onboarding 和开发一致性

### 方案变更
1. **Agent 记忆管理实现延迟**
   - Session 计划完整实现（Redis + PostgreSQL）
   - 代码中只实现了 Redis 短期记忆，长期记忆未完成
   - 原因：优先级调整，先验证核心 Agent 功能

---

## 4. 技术域分布

| 技术域 | 涉及决策 | 置信度 |
|--------|---------|--------|
| **架构层**（模块设计/服务拆分/依赖管理） | 1. Monorepo 选型（Turborepo）<br>2. 前后端分离架构（Next.js + tRPC） | 🟢 高 |
| **数据层**（状态管理/持久化/缓存） | 3. 多租户 schema 隔离<br>4. 实时协作数据同步（Yjs）<br>5. 缓存策略（Redis） | 🟢 高 |
| **Agent 层**（LLM 调用/工具调用/记忆管理） | 6. Agent 工具模式架构<br>7. 多模型支持（OpenAI + Claude）<br>8. 记忆管理设计 | 🟡 中 |
| **工程化层**（构建/测试/CI） | 9. Turborepo 构建缓存<br>10. 分层测试策略<br>11. 环境配置管理 | 🟡 中 |
| **性能层**（并发/缓存/优化） | 12. WebSocket 连接管理<br>13. Redis Pub/Sub 广播<br>14. 数据库连接池 | 🟢 高 |
| **安全层**（认证/授权/审计） | 15. JWT 基础认证<br>16. 多租户数据隔离 | 🔴 低 |

---

## 5. 面试价值评估

### 高价值话题（🟢 高置信度）
1. **Monorepo 选型决策**：Turborepo vs Lerna vs Nx 的深度对比
2. **多租户架构实现**：Schema 隔离的优缺点，扩展性考虑
3. **实时协作技术选型**：CRDT vs OT 的技术决策过程
4. **类型安全全栈开发**：tRPC + TypeScript 的端到端类型安全

### 中价值话题（🟡 中置信度）
1. **AI Agent 架构设计**：工具模式、执行引擎、记忆管理
2. **部署策略演进**：从开发到生产的部署方案选择
3. **测试策略设计**：复杂系统的分层测试方法

### 风险话题（避免主动提及）
1. **安全审计缺失**：企业级安全特性未实现
2. **监控系统空白**：生产可观测性不足
3. **性能优化待完善**：缓存策略不完整

---

## 6. 项目成熟度评估

### 架构完整性：8/10
- 核心架构决策合理且有技术深度
- 技术栈选型现代且匹配业务需求
- 扩展性考虑充分（多租户分片、Agent 工具扩展）

### 实现完成度：6/10
- 核心功能基本实现（多租户、实时协作、基础 Agent）
- 工程化基础扎实（monorepo、类型安全、测试）
- 生产就绪特性缺失（监控、安全、性能优化）

### 技术深度：7/10
- 涉及多个前沿技术领域（CRDT、AI Agent、多租户）
- 技术决策有充分论证和对比分析
- 实现中体现了对技术原理的理解

### 面试展示价值：9/10
- 项目复杂度适中，能展示全栈能力
- 技术决策有故事可讲（为什么选 A 不选 B）
- 涉及企业级关注点（多租户、实时协作、AI 集成）