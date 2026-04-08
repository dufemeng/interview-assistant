---
name: interview-assistant
description: Generates personalized technical interview questions and STAR story cards from a user's Claude Code CLI session history and project codebase, then runs an interactive mock interview with real-time scoring and feedback. Use this skill whenever a user wants to prepare for a technical interview, especially when they built a project using Claude Code or other AI-assisted tools. Trigger on phrases like "帮我准备面试", "面试准备", "面试题", "模拟面试", "help me prepare for my interview", "generate interview questions about my project", "turn my work into interview stories", "I have an interview next week about my project", or any time someone wants to talk about their engineering decisions in an interview context. Don't wait for explicit mention of "Claude Code" — if someone built a project and needs interview prep, use this skill.
---

# Interview Assistant

根据工程师的 Claude Code CLI session 历史和项目代码，生成定制化面试题和 STAR 故事卡，然后直接开始交互式模拟面试。

核心价值：**被提问 → 尝试回答 → 立即获得评分和完美答案**——不是生成一堆文件让你自己复习，而是直接练起来。

---

## 使用前提

- 已安装 Claude Code CLI，且 `~/.claude/projects/` 下有 `.jsonl` session 文件
- Node.js 18+（运行 `session-extractor.mjs`）
- 需要分析的项目代码在本地

---

## 工作流程

### Step 1 — 自动提取（运行脚本）

使用 Bash 工具运行提取脚本：

```bash
bash {SKILL_DIR}/scripts/run.sh
```

如果用户在消息中提供了项目路径，带上路径参数：

```bash
bash {SKILL_DIR}/scripts/run.sh /path/to/your/project
```

**执行后验证**：
- 检查脚本输出，确认 `.interview-docs/extracted_decisions.md` 和 `.interview-docs/code_summary.md` 已生成
- 若 `.interview-docs/extracted_decisions.md` < 5KB：提示用户 "Session 数据较少，知识图谱将主要依赖代码摘要"

**重复练习检测**：脚本完成后检查 `.interview-docs/interview_questions.md` 是否存在：
- **存在** → 询问用户：「检测到之前的分析结果，直接开始面试还是重新分析？」
  - 选「直接开始」→ 执行 `bash {SKILL_DIR}/scripts/extract_decision_count.sh` 获取 D，**跳到 Step 3**
  - 选「重新分析」→ 继续 Step 2
- **不存在** → 继续 Step 2

---

### Step 2 — 分析与准备

询问用户：

1. **目标职级**：资深前端 / 全栈工程师 / Agent 工程师
2. **目标 JD**（可选）：是否有招聘描述文本？

然后**串行**执行以下步骤（每步完成后告知用户进度）：

**2a — 构建项目知识图谱**

读取 `.interview-docs/extracted_decisions.md`、`.interview-docs/code_summary.md` 和 `{SKILL_DIR}/references/01-project-knowledge-builder.md`，交叉印证两份文档生成知识图谱，保存到 `.interview-docs/project_knowledge_graph.md`。

告知用户：「✅ 知识图谱已生成，正在生成面试题...」

**2b — 生成面试题**

读取 `.interview-docs/project_knowledge_graph.md` 和 `{SKILL_DIR}/references/02-interview-generator.md`，基于 TOP D 高价值决策（优先 🟢 高置信度）每条生成 5 道题（基础确认题×1、深度追问题×3、扩展场景题×1）+ 评分要点（✅期待听到 / ❌警惕信号），保存到 `.interview-docs/interview_questions.md`。

告知用户：「✅ 面试题已生成，正在生成故事卡...」

**2c — 生成 STAR 故事卡**

读取 `.interview-docs/project_knowledge_graph.md` 和 `{SKILL_DIR}/references/03-story-card-builder.md`，将 TOP D 决策整理为可直接口述的 STAR 故事卡（每张 200–300 字），保存到 `.interview-docs/story_cards.md`。

告知用户：「✅ 故事卡已生成」

**2d — 提取决策总数**

```bash
bash {SKILL_DIR}/scripts/extract_decision_count.sh
```

捕获输出中的 `DECISION_COUNT=D`，记录 D 值。

告知用户：「分析完毕，共 D 个决策，开始面试？」

---

### Step 3 — 模拟面试

**开始前先写入会话头：**

```bash
bash {SKILL_DIR}/scripts/write_session_header.sh
```

然后读取并严格遵守 `{SKILL_DIR}/references/04-mock-interview.md` 中的全部规则，开始模拟面试：

1. 暖场题（不评分，不计入进度）
2. 按置信度顺序逐决策提问
3. 每题评分（A/B/C）并给出对应反馈
4. 每个决策完成后追加写入评分记录：
   ```bash
   bash {SKILL_DIR}/scripts/write_session_header.sh --append-decision --decision "决策标题" --score "评分"
   ```
5. 询问「已完成第 M 个决策（共 D 个），已问 N 题，继续还是结束？」

---

### Step 4 — 面试总结

面试结束后，生成完整总结，使用 Write 工具将内容追加到 `.interview-docs/mock_interview_summary.md`（总结是 Claude 生成的多行内容，直接用原生文件工具写入，无需脚本中转）：

```
## 模拟面试总结

**总题数**：X 题
**评分分布**：A × N / B × N / C × N

### 强项 / 需要加强 / 建议复习（指向具体故事卡和面试题编号）
```

告知用户所有输出文件位置。

---

## 文件结构

```
interview-assistant/
├── SKILL.md              ← 本文件（skill 定义）
├── README.md             ← 使用说明
├── install.sh            ← 一键安装脚本
├── scripts/
│   ├── session-extractor.mjs       ← 三层过滤提取 session 决策对话
│   ├── code_analyzer.sh            ← 提取代码架构摘要
│   ├── run.sh                      ← 编排入口
│   ├── extract_decision_count.sh   ← 提取决策总数 D
│   └── write_session_header.sh     ← 写入会话头 / 追加评分记录
├── references/
│   ├── 01-project-knowledge-builder.md  ← Step 2a Prompt 模板
│   ├── 02-interview-generator.md         ← Step 2b Prompt 模板
│   ├── 03-story-card-builder.md          ← Step 2c Prompt 模板
│   └── 04-mock-interview.md              ← Step 3 面试官行为准则
└── evals/
    └── evals.json
```

---

## 边界处理

**session 数据稀少**：若 `.interview-docs/extracted_decisions.md` < 5KB，提示用户 "Session 数据较少，知识图谱将主要依赖代码摘要"。

**无 git 仓库**：`code_summary.md` 中 git 历史为空，跳过该节，其余正常处理。

**session 目录不存在**：提示用户确认 Claude Code CLI 已安装并使用过（`~/.claude/projects/` 目录需存在）。

