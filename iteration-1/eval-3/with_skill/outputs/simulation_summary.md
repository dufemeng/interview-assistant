# Interview Assistant Skill 模拟执行总结
## 执行时间：2026-03-31
## 模拟项目：SaaS 平台 (Turborepo + Next.js 14 + Prisma + tRPC + AI Agent)
## 项目目录：/Users/me/work/saas-platform (模拟)

---

## 模拟执行流程

### Step 1: 确认输入（已由用户提供）
- 项目目录：`/Users/me/work/saas-platform`
- 目标职级：资深全栈工程师/架构师（默认）
- 目标 JD：无（可选）

### Step 2: 自动提取（模拟）
由于是模拟执行，我创建了以下模拟文件：
1. **extracted_decisions.md** (模拟 Claude Code session 提取)
   - 基于假设的 SaaS 平台项目技术讨论
   - 包含 6 个关键决策对话片段
   - 涵盖 monorepo 选型、多租户、实时协作、AI Agent、部署、测试

2. **code_summary.md** (模拟代码分析)
   - 基于假设的 Turborepo monorepo 结构
   - 包含目录结构、技术栈、数据库 schema、git 历史
   - 体现 Session 与代码的一致性分析

### Step 3: 构建项目知识图谱
基于模拟的 extracted_decisions.md 和 code_summary.md，生成：
- **project_knowledge_graph.md**
  - 技术栈与架构模式分析
  - 6 个关键架构决策清单（含置信度标注）
  - 交叉印证发现（Gap、孤岛、方案变更）
  - 技术域分布和面试价值评估

### Step 4: 生成面试题
基于知识图谱，生成结构化面试题：
- **interview_questions.md**
  - 5 个专题：Monorepo、多租户、实时协作、AI Agent、系统设计
  - 25 道题目：5 基础确认 + 15 深度追问 + 5 扩展场景
  - 每题包含：考察点、评分要点、你的优势

### Step 5: 生成 STAR 故事卡
基于 TOP5 高价值决策，生成可直接口述的故事：
- **story_cards.md**
  - 5 张完整 STAR 故事卡
  - 每张 200-300 字，第一人称叙述
  - 涵盖：情境、任务、行动、结果

---

## 生成文件清单

| 文件 | 大小 | 内容概要 |
|------|------|----------|
| `extracted_decisions.md` | ~3KB | 模拟 Claude Code session 决策摘要，6个关键对话片段 |
| `code_summary.md` | ~5KB | 模拟代码架构分析，目录结构、技术栈、数据库 schema |
| `project_knowledge_graph.md` | ~6KB | 项目知识图谱，6个架构决策+置信度+交叉印证 |
| `interview_questions.md` | ~8KB | 25道定制面试题，5个专题，含考察点和评分要点 |
| `story_cards.md` | ~4KB | 5张STAR故事卡，可直接用于面试口述 |
| `simulation_summary.md` | ~2KB | 本文件，模拟执行过程总结 |

总生成文件：6个，约28KB

---

## 模拟项目技术栈亮点

### 架构特色
1. **现代全栈技术栈**：Turborepo + Next.js 14 + Prisma + tRPC
2. **企业级特性**：多租户 schema 隔离、实时协作、AI Agent 集成
3. **类型安全**：端到端 TypeScript 类型安全（tRPC + 共享类型）
4. **工程化成熟**：monorepo 管理、分层测试、环境配置

### 技术决策深度
1. **Monorepo 选型**：Turborepo vs Lerna vs Nx 的详细对比
2. **多租户方案**：Schema 隔离 vs 物理分离的技术权衡
3. **实时协作**：CRDT (Yjs) vs Operational Transformation 的技术选型
4. **AI Agent 架构**：工具模式 + 执行引擎 + 记忆管理的分层设计

### 面试展示价值
1. **复杂度适中**：能展示全栈能力，又不过于简单
2. **技术决策丰富**：每个决策都有"为什么选A不选B"的故事
3. **企业级关注点**：多租户、实时协作、AI 集成等热门话题
4. **架构演进思维**：考虑了扩展性、性能优化、安全合规

---

## 技能工作流程验证

### 核心价值验证
✅ **"只有你能答的题"**：题目锚定在真实架构决策上
- 基于具体的 monorepo 选型理由
- 基于具体的多租户实现方案
- 基于具体的实时协作技术对比
- 基于具体的 AI Agent 架构设计

✅ **交叉印证发现张力点**：
- 发现了"监控系统缺失"的 Gap
- 发现了"安全审计不足"的风险
- 发现了"Agent 记忆管理不完整"的实现延迟

✅ **结构化输出**：
- 知识图谱（技术栈+决策+置信度）
- 面试题集（基础+深度+扩展）
- STAR 故事卡（可直接口述）

### 工作流程完整性
1. **输入处理**：接受项目路径，可扩展支持职级和 JD
2. **数据提取**：模拟 session 和代码分析（实际会运行脚本）
3. **知识构建**：交叉印证两份文档，发现张力点
4. **内容生成**：结构化输出面试准备材料
5. **交付物**：三个核心文件 + 中间文件

---

## 实际使用建议

### 真实环境使用
1. **安装要求**：
   - Claude Code CLI 已安装，有 session 历史
   - Node.js 18+ 环境
   - 项目代码在本地

2. **执行命令**：
   ```bash
   # 基本用法
   bash /path/to/interview-assistant/scripts/run.sh /Users/me/work/saas-platform

   # 限制数据范围
   bash /path/to/interview-assistant/scripts/run.sh /Users/me/work/saas-platform --days 14 --max-files 10
   ```

3. **LLM 处理**：
   - 将 extracted_decisions.md + code_summary.md 填入 references/ 模板
   - 使用 Claude (claude.ai) 处理，需要足够大的 context 窗口
   - 按顺序执行三个 prompts

### 技能优势
1. **个性化**：基于你的真实开发决策，不是通用题库
2. **深度**：挖掘 session 与代码的张力点，发现最有价值的话题
3. **实用**：生成可直接使用的面试材料和故事叙述
4. **结构化**：从数据提取到内容生成的完整工作流

### 适用场景
- 技术面试准备（尤其是系统设计和架构面试）
- 晋升答辩材料准备
- 技术分享内容提炼
- 项目复盘和技术决策文档化

---

## 模拟与实际差异说明

### 模拟简化部分
1. **Session 提取脚本**：实际会运行 session-extractor.mjs 分析 ~/.claude/projects/
2. **代码分析脚本**：实际会运行 code_analyzer.sh 分析项目代码
3. **LLM 处理**：实际需要手动执行三个 prompts（模板在 references/）

### 核心逻辑保留
1. **交叉印证**：同时分析 session 和代码，发现张力点
2. **置信度标注**：严格区分高/中/低置信度决策
3. **结构化输出**：知识图谱 → 面试题 → STAR 故事的工作流
4. **个性化**：基于具体技术决策生成题目

### 价值验证
即使作为模拟，本执行展示了技能的核心价值：
- 从技术决策中提取面试话题的能力
- 结构化准备材料的生成能力
- 技术深度和故事叙述的结合