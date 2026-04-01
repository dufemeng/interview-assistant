# 视频脚本生成 Agent 项目面试回答要点

## 项目 STAR 框架总结

### S（Situation，背景）
我们公司的业务同学和市场部经常需要制作 DSP 投放视频，但脚本完全靠手写，内容单一、效率低、跟不上市场节奏。这是一个真实存在的工作效率痛点，业务方每月需要生成上百个视频脚本，手动创作耗时耗力。

### T（Task，挑战/任务）
我设计了一个批量生成视频脚本的 Agent 平台，核心挑战包括：
1. **技术侧**：需要处理多步骤的脚本生成流程，支持条件分支（不同平台不同风格）
2. **性能侧**：批量生成时需要管理并发，避免 LLM API 的 Rate Limit
3. **体验侧**：生成过程较慢，需要提供实时进度反馈
4. **可靠性**：长任务需要支持中断恢复和错误重试

### A（Action，行动）
技术选型上我选择了 NestJS + LangGraph.js + BullMQ 技术栈：

**1. LangGraph.js Agent 编排**
- 使用 StateGraph 管理多步骤状态流转，State 设计包含：
  - `messages`: 对话历史（使用 addMessages reducer 自动追加）
  - `userIntent`: 用户原始请求（主题、风格、平台等）
  - `scripts`: 生成的脚本列表
  - `currentStep`: 当前执行步骤（解析意图→生成大纲→扩写脚本→审核）
  - `error`: 错误信息（用于条件路由）
- 设计条件边实现动态路由：根据平台类型走不同的生成路径
- 集成 Checkpointer（PostgresSaver）支持状态持久化和断点续传

**2. BullMQ 异步任务管理**
- 用户提交任务后立即返回 taskId，实际处理通过 BullMQ 队列异步执行
- 设置 concurrency: 3，限制同时处理的 LLM 调用数量，避免 Rate Limit
- 实现指数退避重试：attempts: 3, backoff: { type: 'exponential', delay: 1000 }
- 通过 Redis Pub/Sub + SSE 实现实时进度推送

**3. NestJS 模块化架构**
- 按功能域划分 Module：AuthModule、TaskModule、VideoModule、AgentModule
- 使用依赖注入管理 BullMQ Queue、PrismaService、RedisClient 等依赖
- 全局管道校验：ValidationPipe + class-validator 确保输入安全
- 统一响应拦截器：包装所有响应为 { success, data, message, timestamp } 格式

**4. Streaming 用户体验优化**
- 实现 SSE（Server-Sent Events）接口推送生成进度
- 前端使用 EventSource API 接收实时更新
- 进度信息包括：当前步骤、已生成脚本数、预估剩余时间

### R（Result，结果）
- **效率提升**：从手动编写每个脚本 30-60 分钟，降低到批量生成 10 个脚本约 5-8 分钟
- **成本控制**：通过 LLM 结果缓存（Redis + SHA256(prompt)），相同请求命中率约 15%，节省 Token 成本
- **系统可靠性**：BullMQ 重试机制将任务失败率从初期的 8% 降低到 2% 以下
- **用户体验**：Streaming 进度反馈使用户等待焦虑感显著降低，用户调研满意度提升 40%

---

## 关键问题回答要点

### 问题 1：LangGraph.js vs LangChain LCEL 选型

**核心回答要点**：
1. **业务需求驱动**：视频脚本生成不是简单的单次问答，而是多步骤流程（解析需求→生成大纲→分场景扩写→风格适配→质量审核）
2. **状态管理需求**：需要在不同步骤间共享和更新复杂状态（用户意图、已生成内容、当前进度等）
3. **条件分支需求**：不同平台（抖音/快手/微博）需要不同的生成策略和风格
4. **可中断/可恢复**：批量任务可能运行时间长，需要支持暂停和恢复

**技术细节补充**：
- State 设计使用了 Annotation.Root + addMessages reducer 自动管理对话历史
- 条件边通过 `toolsCondition` 检测是否需要调用工具，自定义路由函数处理业务分支
- 使用 PostgresSaver 作为 Checkpointer，支持生产环境的状态持久化

**反思与权衡**：
- LangGraph.js 学习曲线较陡，但带来的状态管理和可调试性价值很大
- 对于简单场景（如单次问答），LCEL 完全足够且更轻量
- 如果重来，会在项目初期更早引入 LangSmith 进行全链路追踪

### 问题 2：BullMQ 并发控制设计

**核心回答要点**：
1. **Rate Limit 约束**：OpenAI API 有严格的每分钟请求限制，需要精细的并发控制
2. **削峰填谷**：用户可能一次性提交大量任务，需要队列缓冲
3. **任务优先级**：VIP 用户任务需要优先处理

**技术细节补充**：
- BullMQ 相比 Redis List 提供了：自动重试、延迟队列、进度追踪、死信队列、可视化监控
- Job 状态与数据库同步：Worker 开始处理时更新任务状态为 PROCESSING，完成时更新为 COMPLETED
- 幂等性设计：客户端传 X-Idempotency-Key，Interceptor 查 Redis 去重，数据库唯一约束兜底

**容错设计**：
- Worker 崩溃时，BullMQ 会将 active 状态的任务重新放回队列（根据 visibility timeout）
- 指数退避重试：1s → 2s → 4s，避免瞬时故障导致的任务失败
- 死信队列收集最终失败的任务，供人工排查

### 问题 3：NestJS 模块化设计

**核心回答要点**：
1. **项目规模考虑**：预计会有多个功能模块（用户管理、任务管理、脚本生成、视频生成等）
2. **团队协作需求**：清晰的模块边界有利于多人协作开发
3. **TypeScript 支持**：NestJS 对 TypeScript 有原生良好支持

**模块划分示例**：
- `AuthModule`：用户注册登录、JWT 签发校验
- `TaskModule`：任务创建、查询、状态管理
- `AgentModule`：LangGraph Agent 编排和调用
- `VideoModule`：视频生成任务提交和状态追踪
- `SharedModule`：公共组件（PrismaService、RedisService、ConfigService）

**依赖注入实践**：
- BullMQ Queue 在 TaskModule 中注册，通过构造函数注入到 TaskService
- PrismaService 在 SharedModule 中注册并导出，其他模块导入使用
- 使用 forwardRef 解决了 AgentService 和 TaskService 之间的循环依赖

**中间件使用**：
- `JwtAuthGuard`：保护需要认证的接口
- `ValidationPipe`：配合 class-validator 自动校验 DTO
- `LoggingInterceptor`：记录请求日志和耗时
- `TransformInterceptor`：统一响应格式
- `AllExceptionsFilter`：全局异常处理，返回标准错误格式

### 问题 4：Streaming 输出设计

**核心回答要点**：
1. **用户体验优先**：脚本生成可能耗时几分钟，实时反馈至关重要
2. **技术选型依据**：只需服务器向客户端推送进度，无需客户端向服务器发送数据

**SSE 实现细节**：
- NestJS 中使用 `@Sse()` 装饰器创建 SSE 接口
- Controller 订阅 Redis Channel：`redis.subscribe('task:progress')`
- Worker 处理进度更新时发布消息：`redis.publish('task:progress', JSON.stringify(progress))`
- 前端使用 `EventSource('/api/tasks/{taskId}/progress')` 接收更新

**连接可靠性**：
- 每个 SSE 连接关联具体的 taskId
- 进度状态存储在 Redis 中，key 为 `task:progress:{taskId}`
- 连接断开重连后，前端先查询当前进度，再继续接收实时更新
- 设置心跳机制：每 30 秒发送 `:` 注释保持连接

**与 WebSocket 对比**：
- SSE 基于 HTTP，更简单，自动支持重连
- WebSocket 需要双向通信时才需要（如实时协作编辑）
- 当前场景只需进度推送，SSE 完全足够且实现更简单

### 问题 5：状态持久化与检查点

**核心回答要点**：
1. **长任务可靠性**：脚本生成可能涉及多次 LLM 调用，需要防止中途失败丢失进度
2. **调试需求**：需要能够查看任务执行的历史状态，便于问题排查

**Checkpointer 选型**：
- 开发环境使用 MemorySaver，简单快速
- 生产环境使用 PostgresSaver，持久化到数据库
- 选择理由：已有 PostgreSQL 数据库，避免引入新的存储依赖

**检查点策略**：
- 关键节点后保存：解析意图完成、大纲生成完成、每个脚本生成完成
- 不是每个节点都保存，避免过多的序列化开销
- State 序列化时排除大对象（如原始用户上传的文件）

**状态设计优化**：
- State 中只存储必要的最小数据
- 对话历史使用 addMessages reducer 自动管理
- 定期清理过期的检查点（如 30 天前的）

---

## 技术难点与解决方案

### 难点 1：LLM 调用成本控制
**问题**：批量生成时 LLM Token 消耗大，成本高
**解决方案**：
1. **结果缓存**：Redis 缓存相同 Prompt 的生成结果，key = SHA256(model + prompt)
2. **模型分级**：简单任务用 GPT-4o-mini，复杂任务用 GPT-4o
3. **Prompt 优化**：精简 Prompt，减少不必要的上下文
4. **Token 监控**：集成 LangSmith 监控每次调用的 Token 消耗

### 难点 2：批量任务并发冲突
**问题**：多个 Worker 同时处理可能更新同一任务状态
**解决方案**：
1. **乐观锁**：Task 表增加 version 字段，更新时校验 version
2. **状态机校验**：Service 层校验状态转换的合法性
3. **分布式锁**：关键操作使用 Redis SETNX 获取分布式锁

### 难点 3：流式进度同步
**问题**：多实例部署时，进度推送需要跨实例同步
**解决方案**：
1. **Redis Pub/Sub**：所有实例订阅同一 Channel
2. **连接映射**：维护 taskId 到 SSE 连接的映射（Redis 存储）
3. **负载均衡亲和性**：同一任务的请求尽量路由到同一实例

---

## 项目反思与改进方向

### 做得好的地方
1. **技术选型合理**：LangGraph.js + BullMQ + NestJS 组合很好地满足了业务需求
2. **用户体验重视**：Streaming 进度反馈显著提升了用户满意度
3. **可靠性设计**：完整的错误处理和重试机制保证了系统稳定性
4. **可观测性建设**：集成了 LangSmith 和结构化日志，便于调试和监控

### 可以改进的地方
1. **测试覆盖不足**：Agent 逻辑测试较难，需要加强集成测试和 E2E 测试
2. **配置管理**：环境变量分散，可以引入 ConfigModule 统一管理
3. **部署自动化**：目前部署流程较手动，可以引入 CI/CD 流水线
4. **多租户支持**：当前是单租户设计，扩展为 SaaS 需要架构调整

### 如果重来一次
1. **更早引入 LangSmith**：在开发初期就集成，便于调试和优化
2. **设计更灵活的插件系统**：支持自定义脚本模板和生成策略
3. **加强性能监控**：更细粒度的性能指标收集和分析
4. **文档自动化**：自动生成 API 文档和架构图

---

## 面试技巧建议

### 回答结构建议
1. **STAR 框架**：始终按照 Situation → Task → Action → Result 的结构组织回答
2. **具体细节**：提到具体的技术名称、配置参数、性能数据
3. **业务价值**：将技术决策与业务价值关联，说明为什么这样做
4. **反思总结**：每个决策都谈谈收获和改进想法

### 技术深度展示
1. **原理理解**：不仅要会用，还要理解底层原理（如 LangGraph State 管理机制）
2. **权衡思考**：展示技术选型的权衡过程，为什么选 A 不选 B
3. **扩展思维**：讨论如果需求变化，架构如何演进
4. **生产意识**：考虑监控、告警、部署、运维等生产环境问题

### 沟通表达建议
1. **自信从容**：对自己的技术决策有信心，但保持开放态度
2. **结构化表达**：使用"第一、第二、第三"或"首先、然后、最后"等结构词
3. **举例说明**：用具体的代码片段或配置示例说明观点
4. **互动交流**：适当询问面试官反馈，展示合作态度