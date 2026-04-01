# 面试助手 Skill 实施方案

## 一、Skill 定位

### 核心问题

用 Claude Code CLI 高强度开发后，工程师面临一个尴尬处境：

- **代码在仓库里**——可以 `git log`、可以 `grep`，但代码本身不说明"为什么这样做"
- **决策在 session 里**——大量的技术讨论、方案取舍、踩坑复盘都藏在 `.jsonl` 文件里，但 session 体积可达 100M+，无法直接阅读
- **面试时两边都说不清楚**——代码说不出决策背景，session 翻不到关键片段，最终只能讲"我用了 XXX 框架"的表层话

### 目标用户

用过 AI 辅助工具（Claude Code / Cursor / Windsurf 等）高强度开发过项目、项目决策散落在对话记录里、需要准备技术面试的工程师。不限工作年限，不限具体工具，不限技术方向。

### 核心价值主张

生成**"只有你能答的题"**，而不是通用八股题库。

面试官最怕候选人只会背答案。本 Skill 的核心差异在于：
- 题目基于你的真实架构决策生成，问的是"你当时为什么这样选择"
- 答案锚定在你的 session 里的原话和代码里的实现
- 连追问都是基于你项目的真实漏洞和取舍点设计的

### 当前范围

**仅覆盖 Claude Code CLI 场景**，即 `~/.claude/projects/` 目录下 `.jsonl` 格式的 session 文件。其他工具（Cursor、Windsurf 等）的适配列为 P2。

---

## 二、安装与使用

### 安装（一行命令）

```bash
curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
```

安装内容：
- `~/.interview-assistant/` — 工具脚本（session-extractor.mjs、code_analyzer.sh、run.sh、prompts/）
- `~/.claude/commands/interview-assistant.md` — Claude Code CLI 斜杠命令
- Shell alias `interview-assistant`（写入 `.zshrc` / `.bashrc`）

前提：已安装 Claude Code CLI（[docs.anthropic.com/claude-code](https://docs.anthropic.com/en/docs/claude-code)）和 Node.js 18+。

### 使用方式：Claude Code CLI（全自动）

在任意项目目录打开 Claude Code CLI，输入：

```
/interview-assistant /path/to/your/project
```

Claude 会自动执行全部 5 个步骤：
1. **确认输入** — 询问目标职级、JD（可选）
2. **自动提取** — 运行脚本生成 `extracted_decisions.md` + `code_summary.md`
3. **构建知识图谱** — Claude 读取两份摘要，生成交叉印证的知识图谱
4. **生成面试题** — 基于 TOP5 决策生成 20-30 道定制面试题
5. **生成故事卡** — 将决策整理为 5 张 STAR 格式故事卡

**注意**：Step 3-5 现在**完全自动化**，无需手动复制粘贴到 claude.ai，Claude 会在同一会话中使用 Read/Write 工具完成全部工作。

### 直接运行脚本（仅 Step 1-2）

如需单独运行提取脚本：

```bash
# 自动化 Steps 1-2（提取 session 和代码摘要）
bash ~/.interview-assistant/run.sh /path/to/your/project

# session 数据较大时缩减范围
bash ~/.interview-assistant/run.sh /path/to/your/project --days 14 --max-files 10
```

### 更新到最新版

```bash
curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
```

---

## 三、整体架构

```
┌──────────────────────────────────────────────────────────────────────┐
│  输入层                                                               │
│  ┌──────────────┐   ┌──────────────────┐                             │
│  │ .jsonl files │   │  Git 仓库代码     │                             │
│  │ (100M+ raw)  │   │  (项目源码)       │                             │
│  └──────┬───────┘   └────────┬─────────┘                             │
└─────────┼────────────────────┼─────────────────────────────────────┘
          │                    │
┌─────────▼────────────────────▼─────────────────────────────────────┐
│  预处理层 [P0]                                                        │
│  ┌────────────────────┐   ┌──────────────────────────────────────┐  │
│  │  SessionAdapter    │   │  SessionExtractor                    │  │
│  │  (格式统一化)       │   │  (三层过滤：100M → 50KB)             │  │
│  └────────┬───────────┘   └──────────────────┬───────────────────┘  │
└───────────┼──────────────────────────────────┼─────────────────────┘
            │ session 摘要                      │
┌───────────▼──────────────────────────────────▼─────────────────────┐
│  知识图谱构建层 [P0]                                                  │
│  ┌────────────────────────┐   ┌──────────────────────────────────┐  │
│  │ CodeArchitectureAnalyzer│   │  ProjectKnowledgeBuilder         │  │
│  │  (4 命令代码摘要)        │   │  (融合两路摘要 → 知识图谱)        │  │
│  └────────────────────────┘   └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                         │ 统一项目知识图谱
┌────────────────────────────────────────▼──────────────────────────┐
│  分析层 [P0/P1]                                                     │
│  ┌───────────────────┐  ┌─────────────────┐  ┌──────────────────┐  │
│  │ DecisionAnalyzer  │  │ TopicClassifier │  │  GapDetector     │  │
│  │ [P0] 决策清单+置信度│  │ [P0] 技术域分类 │  │  [P1] 说了没做到 │  │
│  └───────────────────┘  └─────────────────┘  └──────────────────┘  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  TimelineReconstructor [P1] 认知进化轨迹                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
                                         │ 结构化分析结果
┌────────────────────────────────────────▼──────────────────────────┐
│  生成层 [P0/P1]                                                     │
│  ┌──────────────┐  ┌────────────────────┐  ┌────────────────────┐  │
│  │ ValueRanker  │  │ InterviewGenerator │  │ StoryCardBuilder   │  │
│  │ [P0] JD 匹配 │  │ [P0] 三类题生成    │  │ [P0] STAR 故事卡   │  │
│  └──────────────┘  └────────────────────┘  └────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  ExtensionQuestionGenerator [P1] "如果……你怎么改"系列题        │  │
│  └───────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
                                         │ 面试题库 + 故事卡
┌────────────────────────────────────────▼──────────────────────────┐
│  训练层 [P1]                                                        │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  PressureTester - 最强反驳集，模拟"你的项目都是 AI 写的"挑战    │  │
│  └───────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

**MVP 范围（P0）**：SessionAdapter → SessionExtractor → CodeArchitectureAnalyzer → ProjectKnowledgeBuilder → DecisionAnalyzer → TopicClassifier → ValueRanker → InterviewGenerator → StoryCardBuilder

---

## 四、各组件详细设计

### 预处理层（P0）

#### 1. `SessionAdapter` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | 原始 `.jsonl` 文件路径（Claude Code CLI 格式） |
| **输出** | 标准化的 JSON 数组，每条消息包含 `{role, content, timestamp, sessionId}` |
| **核心逻辑** | 解析 Claude Code CLI 的 `.jsonl` 格式，将每行 JSON 反序列化，过滤掉工具调用噪声（`tool_use`/`tool_result` 类型的块），只保留 `text` 类型内容 |
| **实现方式** | Node.js 脚本 |
| **边界处理** | 文件编码异常时跳过该行并记录警告；`content` 为数组时拍平提取文本；`timestamp` 缺失时用文件修改时间补全 |

#### 2. `SessionExtractor` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | 标准化消息数组（来自 SessionAdapter） |
| **输出** | `extracted_decisions.md`，约 30–50KB |
| **核心逻辑** | **三层过滤**：① 文件级：只处理最近 30 天、体积最大的 20 个 session 文件；② 消息级：丢弃纯代码块（`\`\`\`` 占比 > 70%）、长度 < 50 字的对话，优先保留 human turn；③ 语义级：用关键词过滤保留含"为什么/方案/决定/选择/不用/改成"的消息 |
| **实现方式** | Node.js 脚本 |
| **边界处理** | 全部过滤完后输出为空时，降级为只保留最长的 20 条 human turn 消息 |

> 设计原因：human turn 比 assistant turn 更有面试价值。Assistant 的回答是通用知识，而你提问的方式、你描述的约束条件、你的追问方向，才反映了你真实的技术判断力。

---

### 知识图谱构建层（P0）

#### 3. `CodeArchitectureAnalyzer` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | 项目根目录路径 |
| **输出** | `code_summary.md`，约 5–10KB |
| **核心逻辑** | 执行 4 条命令：① `tree -L 3 --gitignore` 获取目录结构；② 读取 `package.json`/`pyproject.toml` 获取依赖栈；③ `git log --oneline -50` 获取最近提交历史；④ 读取 `src/` 下各模块的 `index.ts` / `__init__.py` 等入口文件（不全量读代码） |
| **实现方式** | Shell 脚本 |
| **边界处理** | `tree` 命令不存在时用 `find` 替代；git 历史为空时跳过该步骤；入口文件超过 500 行时只取前 50 行 |

#### 4. `ProjectKnowledgeBuilder` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | `extracted_decisions.md`（session 摘要）+ `code_summary.md`（代码摘要）**同时输入** |
| **输出** | `project_knowledge_graph.md`，包含：技术栈决策、架构模式、关键取舍点、置信度标注 |
| **核心逻辑** | Claude 使用 **Read 工具**读取两份摘要，在同一会话中完成交叉印证：session 里说"选了 X"在代码里是否有实现，代码里出现的模块在 session 里是否有讨论 |
| **实现方式** | Claude Code CLI 自动化（使用 Read/Write 工具，无需手动复制粘贴） |
| **边界处理** | 两份摘要合计超过 context window 时，优先截断 session 摘要（代码结构是事实，session 摘要可以有损）；session 为空时降级为仅基于代码分析 |

> 设计原因：必须在同一上下文中融合两路信息。如果先读代码再搜 session，或者先读 session 再看代码，LLM 在第二步时已经失去了第一步的细节，无法做有效交叉印证。一次性融合才能发现"session 里说要做 X，但代码里没有 X 模块"这类信息，这正是 GapDetector 的基础数据。

---

### 分析层（P0/P1）

#### 5. `DecisionAnalyzer` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | `project_knowledge_graph.md` |
| **输出** | 架构决策清单，每条决策包含：决策描述、背景、取舍点、置信度（高/中/低） |
| **核心逻辑** | 提取所有带有"选择/弃用/改成/因为/权衡"语义的内容，结构化为决策条目；置信度判断依据：session 和代码都有证据为高，只有 session 提及为中，只从代码推断为低 |
| **实现方式** | LLM 调用 |
| **边界处理** | 决策条目少于 5 条时，提示用户补充项目背景信息 |

#### 6. `TopicClassifier` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | 决策清单 |
| **输出** | 按技术域分类的决策映射表 |
| **核心逻辑** | 将每条决策归入以下分类：架构层（模块设计/服务拆分/依赖管理）/ 数据层（状态管理/持久化/缓存）/ Agent 层（LLM 调用/工具调用/记忆管理）/ 工程化层（构建/测试/CI）/ 性能层（并发/缓存/优化） |
| **实现方式** | LLM 调用（可用规则+LLM 混合） |
| **边界处理** | 无法分类时归入"通用工程实践"；一条决策可以属于多个分类 |

#### 7. `GapDetector` [P1]

| 字段 | 说明 |
|------|------|
| **输入** | `project_knowledge_graph.md`（含交叉印证结果） |
| **输出** | Gap 列表：session 中提及但代码未实现的功能/方案 |
| **核心逻辑** | 从知识图谱中找到"session 说要做/应该做"但"代码里没有对应模块"的条目，生成 Gap 描述和可能的解释（未来规划/临时妥协/技术债） |
| **实现方式** | LLM 调用 |
| **边界处理** | Gap 超过 10 条时，只保留与面试强相关（架构/性能）的 Gap |

#### 8. `TimelineReconstructor` [P1]

| 字段 | 说明 |
|------|------|
| **输入** | 带时间戳的 session 摘要 |
| **输出** | 认知进化时间轴：展示某个关键决策从 V1 想法到最终方案的演进过程 |
| **核心逻辑** | 找到同一个话题在不同时间段的消息，提取其中的方案变化，形成"V1 想用 X → 发现问题 Y → 改用 Z"的叙事结构 |
| **实现方式** | LLM 调用 |
| **边界处理** | session 时间跨度小于 3 天时，该组件输出价值有限，自动降级为"关键转折点"模式 |

---

### 生成层（P0/P1）

#### 9. `ValueRanker` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | 决策清单 + 目标 JD 文本 |
| **输出** | TOP5 高价值决策，附匹配度评分和推荐理由 |
| **核心逻辑** | 将 JD 中的技术关键词（如"微前端/低代码/LLM应用/高并发"）与决策清单逐一对比，按语义匹配度排序；同时考虑决策的独特性（越难被替换的经历排越高） |
| **实现方式** | LLM 调用 |
| **边界处理** | JD 为空时，按"架构层 > Agent 层 > 性能层"的默认优先级排序 |

#### 10. `InterviewGenerator` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | TOP5 决策 + 职级方向（资深前端/全栈/Agent 方向） |
| **输出** | 结构化题库，每条决策对应：基础确认题（×1）/ 深度追问题（×3）/ 扩展场景题（×1） |
| **核心逻辑** | 按职级调整难度：资深前端侧重"工程化决策背后的架构考量"；全栈侧重"前后端协作边界和数据一致性"；Agent 方向侧重"LLM 调用可靠性、上下文管理、工具设计" |
| **实现方式** | Claude Code CLI 自动化（Claude 使用 Read 工具读取知识图谱，使用 Write 工具输出面试题） |
| **边界处理** | 同一个决策点生成的题目如果高度重复，要求 LLM 从不同维度追问（技术选型角度/可靠性角度/扩展性角度）；每道题必须引用具体模块名 |

#### 11. `StoryCardBuilder` [P0]

| 字段 | 说明 |
|------|------|
| **输入** | TOP5 决策 + 对应的 session 原文片段 |
| **输出** | STAR 格式故事卡，可直接口述，每张 200–300 字 |
| **核心逻辑** | S（情境）：项目背景 + 面临的技术约束；T（任务）：需要解决的具体问题；A（行动）：你的决策过程和取舍理由；R（结果）：实现效果或学到的教训 |
| **实现方式** | Claude Code CLI 自动化（Claude 使用 Read 工具读取知识图谱和 session 片段，使用 Write 工具输出故事卡） |
| **边界处理** | session 原文缺失时，降级为只依赖代码摘要生成故事，并在卡片末尾注明"细节待补充" |

#### 12. `ExtensionQuestionGenerator` [P1]

| 字段 | 说明 |
|------|------|
| **输入** | 项目架构知识图谱 |
| **输出** | "如果……你怎么改"系列题，5–10 题 |
| **核心逻辑** | 基于真实架构提出假设性挑战：如"如果用户量增长 100 倍，你的现有架构哪里会先垮？""如果要把这个功能从 Web 移植到移动端，你会改什么？" |
| **实现方式** | LLM 调用 |
| **边界处理** | 生成的问题如果过于通用（不依赖具体项目），要求重新生成，必须引用至少一个具体的模块名或决策点 |

---

### 训练层（P1）

#### 13. `PressureTester` [P1]

| 字段 | 说明 |
|------|------|
| **输入** | 故事卡 + 决策清单 |
| **输出** | 最强反驳集（10–15 条），每条附建议回答思路 |
| **核心逻辑** | 生成两类反驳：① 技术层面："你选 X 而不是 Y，但 Y 在 Z 场景下更合适，你为什么不考虑？"；② 主权层面："这些代码是 AI 写的，你自己真的理解吗？"——针对第二类专门设计"我主导了 XX 决策"的反驳话术 |
| **实现方式** | LLM 调用 |
| **边界处理** | 生成的反驳如果答案中找不到合理应对，标注为"建议面试前补充该知识点" |

---

## 五、关键设计决策

### 1. 为什么不先"了解项目"再搜索 session

**错误的流程**：先读代码 → 构建项目理解 → 再去 session 里搜相关讨论

这样做有两个根本性问题：
1. **信息割裂**：LLM 读完代码再读 session，第一步建立的代码认知在第二步 call 里已经被截断丢失，两次读取的信息无法有效融合
2. **视角偏差**：先看代码会让 LLM 形成"现状即合理"的偏见，看不到 session 里那些"当初想做但没做到"的信息

**正确的做法**：`code_summary.md` 和 `extracted_decisions.md` 必须在**同一个 context window** 里同时输入给 `ProjectKnowledgeBuilder`，让 LLM 在单次推理中完成交叉印证。

> 设计原因：知识图谱的价值不在于记录"做了什么"，而在于发现"说了但没做"和"做了但没想清楚"的张力地带，这正是面试中最有深度的话题来源。

### 2. 为什么职级匹配不是"知识点对照表"

**错误的做法**：把"资深前端"对应到 SOLID 原则，机械地问"你的项目用到了哪些设计模式"

这样的题任何候选人都可以背诵回答，面试官无法判断真实能力。

**正确的做法**：把架构原则和你的具体决策绑定——
- 不是"你了解 SRP 吗？"，而是"你当时把消息队列处理器单独抽成服务，而不是放在主流程里，这个决定背后的 trade-off 是什么？"
- 不是"你知道 DDD 吗？"，而是"你的 Agent 模块和业务逻辑模块有明确的领域边界吗？你是怎么划分的？"

> 设计原因：面试本质是在考察候选人在真实约束下做决策的能力，而不是知识点的覆盖面。只有把原则和具体项目挂钩，才能生成"只有你能答的题"。

### 3. 置信度标注机制

三级置信度的判断标准：

| 置信度 | 判断条件 | 面试使用建议 |
|--------|----------|-------------|
| **高** | session 里有明确讨论 + 代码里有对应实现 | 可直接作为核心故事讲述 |
| **中** | 只在 session 里提及，代码未能确认 / 只从代码推断，session 无讨论 | 可以讲，但要加"当时的考虑是……"而不是"我做了……" |
| **低** | 纯粹推断，无 session 证据，无明显代码证据 | 不建议在面试中主动提及，容易被追问穿帮 |

> 设计原因：低置信度内容如果被当成面试话术使用，一旦面试官追问细节，候选人无法提供具体依据，反而会损害整体印象。宁可少讲，也不要讲不确定的事。

### 4. 三层过滤的设计逻辑

三层过滤必须按**文件级 → 消息级 → 语义级**的顺序执行，原因如下：

- **文件级在最前**：先用元数据（时间、大小）过滤，不需要解析内容，计算成本最低。用最近 30 天、最大的 20 个文件，保证覆盖最活跃的开发阶段
- **消息级在中间**：用结构化规则（长度、代码块占比）过滤，比 LLM 调用便宜几个数量级。纯代码块没有决策信息，短消息缺乏上下文，都应该在这一层剔除
- **语义级在最后**：用关键词匹配做最后一道筛选，只在消息级过滤后的小数据集上运行，避免在 100M 原始数据上跑语义搜索

**为什么 human turn 比 assistant turn 更有价值**：

Assistant 的输出是基于通用知识的生成内容，面试时无法引用"Claude 说……"。但你提问时的措辞体现了：你当时面临什么约束（"我们不能用 Redis，因为……"）、你的判断方向（"我感觉直接用状态机比较合适"）、你的技术品味（你追问的深度）。这些才是面试中可以展示的"判断力"。

---

## 六、MVP 实施步骤

### Step 1：环境诊断

```bash
# 确认 Claude Code CLI session 目录
ls ~/.claude/projects/

# 找出最大的 session 文件（重点处理对象）
find ~/.claude/projects/ -name "*.jsonl" -exec du -sh {} \; | sort -rh | head -20

# 统计总数据量
du -sh ~/.claude/projects/

# 确认 Node.js 版本（需要 18+）
node --version

# 确认项目目录
ls /path/to/your/project/
git -C /path/to/your/project/ log --oneline -5
```

### Step 2：SessionExtractor 脚本

```javascript
#!/usr/bin/env node
/**
 * session-extractor.mjs: 三层过滤，将 100M+ Claude Code CLI session 压缩到 50KB 以内
 * 输出文件：extracted_decisions.md
 * 运行环境：Node.js 18+，零依赖
 */

import fs from 'fs';
import readline from 'readline';
import path from 'path';
import os from 'os';

// ── 配置 ──────────────────────────────────────────────────────────────────────
const SESSION_DIR = path.join(os.homedir(), '.claude', 'projects');
const OUTPUT_FILE = 'extracted_decisions.md';
const DAYS_LIMIT = 30;       // 只处理最近 N 天的文件（可调整，session 较少时可扩大）
const MAX_FILES = 20;        // 最多处理 N 个文件（按大小取最大的；session 超 200MB 时建议改为 10）
const MAX_OUTPUT_KB = 50;    // 目标输出大小上限（超出时脚本会给出警告，不会强制截断）

/** 解析单个 .jsonl 文件，返回标准化消息列表 */
async function loadJsonl(filepath) {
  const messages = [];
  const fileStream = fs.createReadStream(filepath);
  const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });
  const filename = path.basename(filepath);
  let lineno = 0;

  for await (const line of rl) {
    lineno++;
    const trimmed = line.trim();
    if (!trimmed) continue;

    let obj;
    try {
      obj = JSON.parse(trimmed);
    } catch {
      process.stderr.write(`  ⚠️  ${filename}:${lineno} JSON 解析失败，跳过\n`);
      continue;
    }

    const role = obj.role ?? '';
    let content = obj.content ?? '';
    const timestamp = obj.timestamp ?? '';

    // content 可能是数组（多块内容），拍平提取 text
    if (Array.isArray(content)) {
      content = content
        .filter(block => block && typeof block === 'object' && block.type === 'text')
        .map(block => block.text ?? '')
        .join('\n');
    } else if (typeof content !== 'string') {
      content = String(content);
    }

    if (role && content) {
      messages.push({ role, content, timestamp, source_file: filename });
    }
  }
  return messages;
}

/** 第一层：文件级过滤 —— 最近 N 天 + 最大 N 个 */
function layer1FileFilter(sessionDir) {
  const cutoffMs = Date.now() - DAYS_LIMIT * 24 * 60 * 60 * 1000;
  const candidates = [];

  function walk(dir) {
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (err) {
      process.stderr.write(`  ⚠️  跳过无法访问的目录：${dir}（${err.message}）\n`);
      return; // 跳过无权限访问的目录
    }
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.isFile() && entry.name.endsWith('.jsonl')) {
        const stat = fs.statSync(full);
        if (stat.mtimeMs >= cutoffMs) {
          candidates.push({ size: stat.size, filepath: full });
        }
      }
    }
  }
  walk(sessionDir);

  // 按大小降序，取前 MAX_FILES 个
  candidates.sort((a, b) => b.size - a.size);
  const selected = candidates.slice(0, MAX_FILES).map(c => c.filepath);
  console.log(`📂 文件级过滤：找到 ${candidates.length} 个近期文件，选取最大的 ${selected.length} 个`);
  return selected;
}

/** 判断消息是否主要由代码块构成 */
function isMostlyCode(text, threshold = 0.7) {
  const codeBlockChars = [...text.matchAll(/```[\s\S]*?```/g)]
    .reduce((sum, m) => sum + m[0].length, 0);
  return text.length > 0 && codeBlockChars / text.length > threshold;
}

const DECISION_KEYWORDS =
  /为什么|为何|原因|方案|决定|决策|选择|不用|改成|换成|放弃|权衡|取舍|考虑过|试过|坑|问题|瓶颈|优化|重构|架构|设计|模式|策略|实现|方式|why|because|reason|decided|instead|tradeoff|approach|pattern/i;

/** 第二层：消息级过滤 —— 丢弃纯代码块和过短消息 */
function layer2MessageFilter(messages) {
  const filtered = messages.filter(msg => {
    if (isMostlyCode(msg.content)) return false;
    if (msg.content.trim().length < 50) return false;
    return true;
  });
  console.log(`📝 消息级过滤：${messages.length} → ${filtered.length} 条消息`);
  return filtered;
}

/** 第三层：语义级过滤 —— 保留含决策关键词的消息，优先 human turn */
function layer3SemanticFilter(messages) {
  const humanMsgs = messages.filter(m => m.role === 'human' && DECISION_KEYWORDS.test(m.content));
  const assistantMsgs = messages.filter(m => m.role === 'assistant' && DECISION_KEYWORDS.test(m.content));

  // human turn 优先，assistant turn 按 human 数量的一半补充（上限 10 条）
  // 目的：assistant 提供上下文背景，但数量不能超过 human，避免通用内容淹没决策信息
  const assistantLimit = Math.max(10, Math.floor(humanMsgs.length / 2));
  let result = [...humanMsgs, ...assistantMsgs.slice(0, assistantLimit)];
  console.log(`🔍 语义级过滤：human ${humanMsgs.length} 条 + assistant ${Math.min(assistantMsgs.length, assistantLimit)} 条`);

  // 降级：如果语义过滤后为空，保留最长的 20 条 human turn
  if (result.length === 0) {
    console.log('⚠️  语义过滤结果为空，降级为保留最长的 20 条 human turn');
    result = messages
      .filter(m => m.role === 'human')
      .sort((a, b) => b.content.length - a.content.length)
      .slice(0, 20);
  }
  return result;
}

/** 将过滤后的消息写入 Markdown 文件 */
function writeOutput(messages, outputPath) {
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const lines = [
    '# Session 决策提炼\n\n',
    `> 提取时间：${now}  \n`,
    `> 消息数量：${messages.length} 条\n\n`,
    '---\n\n',
  ];

  for (let i = 0; i < messages.length; i++) {
    const msg = messages[i];
    const roleLabel = msg.role === 'human' ? '👤 用户' : '🤖 Claude';
    const ts = msg.timestamp ? msg.timestamp.slice(0, 19).replace('T', ' ') : '时间未知';
    lines.push(`### [${i + 1}] ${roleLabel}  \`${ts}\`  \`${msg.source_file}\`\n\n`);
    lines.push(msg.content.trim() + '\n\n');
    lines.push('---\n\n');
  }

  fs.writeFileSync(outputPath, lines.join(''), 'utf-8');
  const sizeKb = fs.statSync(outputPath).size / 1024;
  console.log(`✅ 输出：${outputPath}  (${sizeKb.toFixed(1)} KB)`);
  if (sizeKb > MAX_OUTPUT_KB) {
    console.log(`⚠️  输出超过 ${MAX_OUTPUT_KB}KB，建议缩减 MAX_FILES 或 DAYS_LIMIT`);
  }
}

async function main() {
  if (!fs.existsSync(SESSION_DIR)) {
    process.stderr.write(`❌ Session 目录不存在：${SESSION_DIR}\n`);
    process.exit(1);
  }

  // 第一层：文件级过滤
  const selectedFiles = layer1FileFilter(SESSION_DIR);
  if (selectedFiles.length === 0) {
    process.stderr.write('❌ 未找到符合条件的 session 文件\n');
    process.exit(1);
  }

  // 加载所有选中文件
  let allMessages = [];
  for (const filepath of selectedFiles) {
    const stat = fs.statSync(filepath);
    console.log(`  📖 加载 ${path.basename(filepath)} (${(stat.size / 1024 / 1024).toFixed(1)} MB)`);
    allMessages = allMessages.concat(await loadJsonl(filepath));
  }
  console.log(`📊 共加载 ${allMessages.length} 条原始消息\n`);

  // 第二层：消息级过滤
  let messages = layer2MessageFilter(allMessages);

  // 第三层：语义级过滤
  messages = layer3SemanticFilter(messages);

  // 写入输出
  writeOutput(messages, OUTPUT_FILE);
}

main().catch(err => {
  process.stderr.write(`❌ 运行失败：${err.message}\n`);
  process.exit(1);
});
```

运行方式：

```bash
node session-extractor.mjs
# 输出：extracted_decisions.md（约 30–50KB）
```

### Step 3：CodeArchitectureAnalyzer

```bash
#!/usr/bin/env bash
# code_analyzer.sh：4 条命令提取代码摘要，输出 code_summary.md

PROJECT_DIR="${1:-.}"
OUTPUT="code_summary.md"

echo "# 代码架构摘要" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "> 生成时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ① 目录结构（最多 3 层）
echo "## 目录结构" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
if command -v tree &>/dev/null; then
    tree "$PROJECT_DIR" -L 3 --gitignore 2>/dev/null >> "$OUTPUT"
else
    find "$PROJECT_DIR" -not -path '*/.git/*' -not -path '*/node_modules/*' \
        -not -path '*/__pycache__/*' | head -100 >> "$OUTPUT"
fi
echo '```' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ② 依赖栈
echo "## 依赖栈" >> "$OUTPUT"
for manifest in package.json pyproject.toml requirements.txt go.mod; do
    if [ -f "$PROJECT_DIR/$manifest" ]; then
        echo "### $manifest" >> "$OUTPUT"
        echo '```' >> "$OUTPUT"
        head -60 "$PROJECT_DIR/$manifest" >> "$OUTPUT"
        echo '```' >> "$OUTPUT"
        echo "" >> "$OUTPUT"
    fi
done

# ③ Git 提交历史（最近 50 条）
echo "## 提交历史（最近 50 条）" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
git -C "$PROJECT_DIR" log --oneline -50 2>/dev/null >> "$OUTPUT" || echo "（无 git 历史）" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# ④ 核心模块入口文件（取前 50 行）
echo "## 核心模块入口" >> "$OUTPUT"
for entry_pattern in "src/index.ts" "src/main.ts" "src/app.ts" "index.ts" \
                     "src/__init__.py" "main.py" "app.py"; do
    entry="$PROJECT_DIR/$entry_pattern"
    if [ -f "$entry" ]; then
        echo "### $entry_pattern" >> "$OUTPUT"
        echo '```typescript' >> "$OUTPUT"
        head -50 "$entry" >> "$OUTPUT"
        echo '```' >> "$OUTPUT"
        echo "" >> "$OUTPUT"
    fi
done

# 模块目录的 index 文件（兼容 macOS 和 Linux）
# 使用 NODE_PATH 前缀剥离方式获取相对路径
_dir=$(cd "$PROJECT_DIR" && pwd)
find "$_dir/src" -name "index.ts" -not -path "*/node_modules/*" 2>/dev/null | head -10 | while read -r f; do
    rel="${f#$_dir/}"
    echo "### $rel" >> "$OUTPUT"
    echo '```typescript' >> "$OUTPUT"
    head -30 "$f" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    echo "" >> "$OUTPUT"
done

SIZE=$(wc -c < "$OUTPUT")
echo "✅ 代码摘要已输出：$OUTPUT（$(( SIZE / 1024 )) KB）"
```

运行方式：

```bash
bash code_analyzer.sh /path/to/your/project
# 输出：code_summary.md（约 5–10KB）
```

### Step 4：ProjectKnowledgeBuilder（自动化）

> **注意**：此步骤现在由 Claude **自动执行**，无需手动复制粘贴！

Claude 使用 **Read 工具**读取 `extracted_decisions.md` 和 `code_summary.md`，在同一会话中完成交叉印证，并自动生成 `project_knowledge_graph.md`。

**实现原理**：
```
┌─────────────────────────────────────────────────────────────┐
│  Step 4 自动化流程                                           │
│                                                             │
│  1. Claude 使用 Read 工具读取 extracted_decisions.md         │
│  2. Claude 使用 Read 工具读取 code_summary.md                │
│  3. Claude 使用 Read 工具读取 references/01-project-         │
│     knowledge-builder.md 获取格式要求                        │
│  4. 在同一会话中交叉印证两份文档                              │
│  5. Claude 使用 Write 工具输出 project_knowledge_graph.md    │
└─────────────────────────────────────────────────────────────┘
```

**输出格式**（自动生成的知识图谱包含）：

```markdown
# 项目知识图谱

## 1. 技术栈与架构模式
- 技术名称 + 选型讨论（session 是否有提及）+ 代码实现状态

## 2. 关键架构决策清单（≥5条）
每条包含：决策描述、背景、取舍、置信度（🟢高/🟡中/🔴低）

## 3. 交叉印证发现
- Gap: session 提到但代码未实现
- 孤岛: 代码有但 session 未讨论
- 方案变更: 思路转变痕迹

## 4. 技术域分布
| 技术域 | 涉及决策 |
|--------|----------|
| 架构层 | ... |
| 数据层 | ... |
```

**Prompt 模板**（供参考，位于 `references/01-project-knowledge-builder.md`）：
```
你是一个技术架构分析师。我会给你两份文档：
1. **Session 摘要**：工程师与 Claude Code 的对话片段
2. **代码摘要**：项目的目录结构、依赖栈、提交历史

请在同一次分析中交叉印证两份文档，构建项目知识图谱...
```

### Step 5：InterviewGenerator（自动化）

> **注意**：此步骤现在由 Claude **自动执行**，无需手动复制粘贴！

Claude 使用 **Read 工具**读取 `project_knowledge_graph.md`，识别 TOP5 高价值决策，并自动生成定制面试题到 `interview_questions.md`。

**实现原理**：
```
┌─────────────────────────────────────────────────────────────┐
│  Step 5 自动化流程                                           │
│                                                             │
│  1. Claude 使用 Read 工具读取 project_knowledge_graph.md     │
│  2. Claude 使用 Read 工具读取 references/02-interview-       │
│     generator.md 获取格式要求                                │
│  3. 识别 TOP5 高价值决策（优先 🟢 高置信度）                  │
│  4. 每条决策生成 5 道面试题：                                 │
│     - 基础确认题 × 1                                        │
│     - 深度追问题 × 3                                        │
│     - 扩展场景题 × 1                                        │
│  5. 质量检查：每道题必须引用具体模块名                        │
│  6. Claude 使用 Write 工具输出 interview_questions.md        │
└─────────────────────────────────────────────────────────────┘
```

**面试题质量标准**（自动强制执行）：
- ✅ 每道题必须引用项目中的具体模块名或技术选型
- ✅ 追问要问 "为什么选 A 不选 B"，不能问 "A 是什么"
- ❌ 避免 "什么是闭包" 这类通用八股题

**职级难度调整**：
- **资深前端**：侧重工程化决策（构建优化/模块化/性能监控）
- **全栈工程师**：侧重前后端协作边界（API 设计/数据一致性）
- **Agent 工程师**：侧重 LLM 调用可靠性（重试/降级/成本控制）

**Prompt 模板**（供参考，位于 `references/02-interview-generator.md`）

### Step 6：StoryCardBuilder（自动化）

> **注意**：此步骤现在由 Claude **自动执行**，无需手动复制粘贴！

Claude 使用 **Read 工具**读取知识图谱中的决策清单和 session 片段，并自动生成 5 张 STAR 格式故事卡到 `story_cards.md`。

**实现原理**：
```
┌─────────────────────────────────────────────────────────────┐
│  Step 6 自动化流程                                           │
│                                                             │
│  1. Claude 使用 Read 工具读取 project_knowledge_graph.md     │
│     中的决策清单                                             │
│  2. Claude 使用 Read 工具读取 references/03-story-card-      │
│     builder.md 获取格式要求                                  │
│  3. 将 TOP5 决策整理为可直接口述的 STAR 故事卡                │
│  4. 写作要求（自动强制执行）：                                │
│     - 每张 200–300 字，语言自然，第一人称                     │
│     - 必须包含具体细节：模块名、技术名称、数据量级             │
│     - 结果诚实，不虚构 KPI                                    │
│  5. Claude 使用 Write 工具输出 story_cards.md                │
└─────────────────────────────────────────────────────────────┘
```

**STAR 格式**：
- **S（情境）**：项目背景 + 技术约束
- **T（任务）**：需要解决的具体技术问题
- **A（行动）**：考虑过哪些方案 → 选了什么 → 为什么
- **R（结果）**：效果、学到什么、如果重来怎么做

**Prompt 模板**（供参考，位于 `references/03-story-card-builder.md`）

---

## 七、使用流程（端到端示例）

以下是一个完整的示例：工程师用两周时间用 Claude Code CLI 开发了一个"智能视频脚本生成 Agent"，session 数据总量 120MB，现在要准备资深前端方向的面试。

### 第一步：环境诊断（约 2 分钟）

```bash
ls ~/.claude/projects/
# 假设输出：my-video-agent/

find ~/.claude/projects/my-video-agent/ -name "*.jsonl" -exec du -sh {} \; | sort -rh | head -5
# 输出示例：
# 45M  session_20260320_abc123.jsonl
# 30M  session_20260318_def456.jsonl
# 25M  session_20260315_ghi789.jsonl
# ...

du -sh ~/.claude/projects/
# 输出：120M  /home/user/.claude/projects/
```

### 第二步：运行 SessionExtractor（约 3–5 分钟）

```bash
node session-extractor.mjs
```

预期输出：
```
📂 文件级过滤：找到 8 个近期文件，选取最大的 8 个
📖 加载 session_20260320_abc123.jsonl (45.0 MB)
📖 加载 session_20260318_def456.jsonl (30.0 MB)
...
📊 共加载 48293 条原始消息

📝 消息级过滤：48293 → 6821 条消息
🔍 语义级过滤：human 312 条 + assistant 156 条
✅ 输出：extracted_decisions.md  (38.2 KB)
```

### 第三步：运行 CodeArchitectureAnalyzer（约 1 分钟）

```bash
bash code_analyzer.sh ~/projects/my-video-agent
# 输出：code_summary.md（约 7KB）
```

### 第四步：Claude 自动化执行 Step 3-5（约 5–8 分钟）

> **注意**：Step 3-5 现在完全自动化！Claude 会在同一会话中使用 Read/Write 工具完成全部工作。

在 Claude Code CLI 中继续：

```
Claude 会自动：
✅ 使用 Read 工具读取 extracted_decisions.md 和 code_summary.md
✅ 使用 Read 工具读取 references/ 下的 Prompt 模板
✅ 生成交叉印证的知识图谱 → project_knowledge_graph.md
✅ 生成定制面试题 → interview_questions.md
✅ 生成 STAR 故事卡 → story_cards.md
```

**预期产出示例（知识图谱）：**
```markdown
## 关键架构决策清单

1. **BullMQ 替代 Agenda 用于视频生成任务队列**
   - 背景：视频生成任务耗时 2–5 分钟，需要可靠的重试机制
   - 取舍：选 BullMQ（Redis-based，可靠性高），放弃 Agenda（MongoDB-based，重试逻辑弱）
   - 置信度：🟢 高（session 有讨论，代码有 src/queues/video.queue.ts）

2. **Prompt 模板外置到 YAML 文件**
   - 背景：迭代 Prompt 需要频繁修改，和代码混在一起难以管理
   - 取舍：YAML 外置（可以不重新部署直接修改），未用数据库（对这个阶段过度设计）
   - 置信度：🟢 高
...
```

### 总耗时（新自动化流程）

| 步骤 | 耗时 |
|------|------|
| 环境诊断 | 2 分钟 |
| SessionExtractor（脚本） | 3–5 分钟 |
| CodeArchitectureAnalyzer（脚本） | 1 分钟 |
| ProjectKnowledgeBuilder（Claude 自动） | 2–3 分钟 |
| InterviewGenerator（Claude 自动） | 2–3 分钟 |
| StoryCardBuilder（Claude 自动） | 2–3 分钟 |
| **合计** | **约 10–15 分钟** |

**vs 旧流程**：从 15–25 分钟减少到 10–15 分钟，且**无需手动复制粘贴**

**最终产出**：
- `extracted_decisions.md`（session 决策提炼）
- `code_summary.md`（代码架构摘要）
- `project_knowledge_graph.md`（知识图谱，含置信度标注）
- `interview_questions.md`（20–30 道定制面试题）
- `story_cards.md`（5 张 STAR 故事卡）

---

## 八、边界情况处理

### 情况 1：session 里全是代码，没有决策对话

**处理策略**：降级为以 `CodeArchitectureAnalyzer` 为主。

```bash
# 检测 session 内容类型（纯 shell，无需 Node.js）
size=$(wc -c < extracted_decisions.md 2>/dev/null || echo 0)
[ "$size" -lt 5000 ] && echo "⚠️ session 内容稀少，建议以代码摘要为主要信息源"
```

在 `ProjectKnowledgeBuilder` Prompt 中注明："Session 摘要内容有限，请主要依据代码摘要推断架构决策，置信度标注为🟡中。"

### 情况 2：session 数据超过 200MB

**处理策略**：调整 `SessionExtractor` 参数，分批处理。

```javascript
// 修改 session-extractor.mjs 顶部配置
const DAYS_LIMIT = 14;   // 缩减到最近 2 周
const MAX_FILES = 10;    // 减少文件数量
```

如仍超出，可以只处理 **最后 5 个最大的 session 文件**（通常对应项目最活跃的阶段）：

```bash
find ~/.claude/projects/ -name "*.jsonl" -exec du -sh {} \; | sort -rh | head -5
```

### 情况 3：用户有多个项目

**处理策略**（P2，当前版本手动处理）：

1. 先确认本次面试针对哪个项目（按 JD 匹配度判断）
2. 手动指定 `SESSION_DIR` 和 `PROJECT_DIR`：

```javascript
// 修改 session-extractor.mjs 中的 SESSION_DIR
const SESSION_DIR = path.join(os.homedir(), '.claude', 'projects', 'my-video-agent');
```

未来的 `ProjectSelector` 组件将自动按 JD 匹配最相关的项目。

### 情况 4：session 来自 Cursor、Windsurf 等其他工具

**处理策略**：`SessionAdapter` 扩展点说明。

当前版本仅支持 Claude Code CLI 的 `.jsonl` 格式。其他工具的 session 格式各异，需要扩展 `SessionAdapter`：

- **Cursor**：通常以 SQLite 数据库存储（`~/.cursor/` 目录），需要添加 SQLite 读取逻辑
- **Windsurf**：格式待调研
- **通用接入**：只要能提取 `{role, content, timestamp}` 三元组，后续流程完全复用

扩展位置：在 `loadJsonl()` 函数中添加格式检测分支，或新增独立的 `loadCursor()` / `loadWindsurf()` 函数。

### 情况 5：生成内容置信度过低

**处理策略**：提示用户人工补充，给出引导问题。

当 `DecisionAnalyzer` 输出中低置信度（🔴）决策占比超过 50% 时，在输出文件末尾追加以下引导：

```markdown
## ⚠️ 置信度不足，建议补充以下信息

请回忆并补充以下问题的答案（直接添加到本文件末尾即可）：

1. 这个项目最难搞定的技术问题是什么？你是怎么解决的？
2. 你在项目中主动做了哪些"不是必须做但你觉得值得做"的工程化决策？
3. 如果重来，你最想推翻哪个技术选择？为什么？
4. 你和 Claude 讨论最多的是什么技术难题？最终结论是什么？
5. 项目目前最大的技术债是什么？是有意识留下的还是无奈妥协的？
```

---

## 九、后续迭代路线图

### P1 迭代（MVP 跑通后）

在至少完成 2 次真实面试、验证 MVP 效果后，推进以下组件：

**GapDetector**
- 目标：找出"session 说了但代码没做到"的地方
- 价值：这些 Gap 往往是最真实的面试话题——"当时为什么没做？""未来打算怎么补？"
- 前提：需要 `ProjectKnowledgeBuilder` 已经产出高质量的交叉印证数据

**TimelineReconstructor**
- 目标：重建认知进化轨迹
- 价值：展示"我当初判断错了，后来发现 XX，改成了 YY"，这类认知迭代叙事比"一开始就做对了"更可信、更有说服力
- 前提：session 时间跨度 > 7 天，且 `SessionExtractor` 保留了时间戳信息

**PressureTester**
- 目标：模拟面试官最难的反驳
- 价值：让用户提前准备"你的代码是 AI 写的"这类质疑的应对话术
- 前提：`StoryCardBuilder` 已产出故事卡，有基础内容可以反驳

### P2 迭代（有真实用户反馈后）

**多工具 SessionAdapter**
- 支持 Cursor、Windsurf、GitHub Copilot 等主流 AI 编程工具的 session 格式
- 设计一套通用的 session 格式协议，各工具实现各自的 Adapter

**ProjectSelector**
- 当用户有多个项目时，自动分析哪个项目与目标 JD 最匹配
- 可以按技术栈匹配度、项目规模、开发强度（session 数量/代码量）综合评分

**AnswerEvaluator**
- 用户录入自己的回答，自动评估：是否引用了具体细节、是否有逻辑漏洞、是否触及了高价值点
- 为每次练习给出改进建议

### 与脚本 Agent 主项目的集成计划

本 Skill 当前作为独立脚本集合存在，未来将作为平台第二个 Agent 模块集成：

**集成时机**：在脚本 Agent 主项目（智能视频脚本生成 Agent）完成 MVP 验收后，即项目具备以下条件时：
- 有稳定的 LangChain.js / LangGraph 调用基础设施
- 有统一的 Prompt 管理机制（外置 YAML 模板）
- 有基础的任务队列和状态管理

**集成方式**：
1. 将 `SessionExtractor` 和 `CodeArchitectureAnalyzer` 封装为 LangChain.js 工具（`Tool`）
2. 将 `ProjectKnowledgeBuilder` → `InterviewGenerator` → `StoryCardBuilder` 的调用链封装为 LangGraph 状态图
3. 提供 CLI 入口：`npx interview-assistant --project ./my-project --jd ./jd.txt --level senior-frontend`

---

创建时间：2026-03-30
