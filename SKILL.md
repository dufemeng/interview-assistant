---
name: interview-assistant
description: Generates personalized technical interview questions and STAR story cards from a user's Claude Code CLI session history and project codebase. Use this skill whenever a user wants to prepare for a technical interview, especially when they built a project using Claude Code or other AI-assisted tools. Trigger on phrases like "帮我准备面试", "面试准备", "面试题", "help me prepare for my interview", "generate interview questions about my project", "turn my work into interview stories", "I have an interview next week about my project", or any time someone wants to talk about their engineering decisions in an interview context. Don't wait for explicit mention of "Claude Code" — if someone built a project and needs interview prep, use this skill.
---

# Interview Assistant

根据工程师的 Claude Code CLI session 历史和项目代码，生成定制化面试题和 STAR 故事卡。

核心价值：生成**"只有你能答的题"**——题目锚定在你的真实架构决策上，而不是通用八股题库。

---

## 使用前提

- 已安装 Claude Code CLI，且 `~/.claude/projects/` 下有 `.jsonl` session 文件
- Node.js 18+（运行 `session-extractor.mjs`）
- 需要分析的项目代码在本地

---

## 工作流程

### Step 1 — 确认输入

询问用户：

1. **项目目录路径**（可选）：`/path/to/your/project`。如果用户未提供，默认使用当前目录（Claude Code 打开的项目根目录）。
2. **目标职级**：资深前端 / 全栈工程师 / Agent 工程师
3. **目标 JD**（可选）：是否有招聘描述文本？

如果用户未提供路径，直接进入 Step 2，脚本会自动使用当前目录。

---

### Step 2 — 自动提取（运行脚本）

使用 Bash 工具运行提取脚本：

```bash
bash {SKILL_DIR}/scripts/run.sh <project_path>
```

**执行后验证**：
- 检查脚本输出中的 JSON 结果，确认 `.interview-docs/extracted_decisions.md` 和 `.interview-docs/code_summary.md` 已生成
- 如果 session 数据量很大（>200MB 或提取时间超过 60 秒），建议用户：
  ```bash
  bash {SKILL_DIR}/scripts/run.sh <project_path> --days 14 --max-files 10
  ```

**边界处理**：
- 若 `.interview-docs/extracted_decisions.md` < 5KB：提示用户 "Session 数据较少，知识图谱将主要依赖代码摘要"
- 若 `code_summary.md` 未生成：检查项目路径是否正确、项目是否包含可识别文件

---

### Step 3 — 构建项目知识图谱

**自动执行步骤**：

1. **使用 Read 工具读取摘要文件**：
   - 读取 `.interview-docs/extracted_decisions.md`
   - 读取 `.interview-docs/code_summary.md`
   - 读取 `{SKILL_DIR}/references/01-project-knowledge-builder.md` 获取详细格式要求

2. **交叉印证分析**（在同一次分析中完成）：
   - 列出技术栈与架构模式
   - 提取至少 5 条关键架构决策（含置信度标注 🟢🟡🔴）
   - 识别 "Gap（说了没做）" / "孤岛（做了没说）" / "方案变更"
   - 按技术域分类（架构层/数据层/Agent层/工程化层/性能层）

   > 关键原则：必须同时基于两份文档做交叉印证，发现"session 说要做但代码没做"的张力点

3. **使用 Write 工具输出结果**：
   - 将知识图谱写入 `.interview-docs/project_knowledge_graph.md`

**输出格式要求**（参考 `references/01-project-knowledge-builder.md`）：
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

## 4. 技术域分布表
```

---

### Step 4 — 生成面试题

**自动执行步骤**：

1. **使用 Read 工具读取输入**：
   - 读取 `.interview-docs/project_knowledge_graph.md`
   - 读取 `{SKILL_DIR}/references/02-interview-generator.md` 获取详细格式要求

2. **分析并生成面试题**：
   - 识别 TOP5 高价值决策（优先选择 🟢 高置信度决策）
   - 每条决策生成 5 道面试题：
     - 基础确认题 × 1（验证候选人真实经历该决策）
     - 深度追问题 × 3（技术选型、可靠性边界、取舍与反思）
     - 扩展场景题 × 1（架构演进能力）

3. **质量检查**（强制执行）：
   - ✅ 每道题必须引用项目中的具体模块名或技术选型
   - ✅ 追问要问 "为什么选 A 不选 B"，不能问 "A 是什么"
   - ❌ 避免 "什么是闭包" 这类通用八股题

4. **使用 Write 工具输出结果**：
   - 将面试题写入 `.interview-docs/interview_questions.md`

**输出格式**：每条决策对应一个章节，包含面试题 + 评分要点

---

### Step 5 — 生成 STAR 故事卡

**自动执行步骤**：

1. **使用 Read 工具读取输入**：
   - 读取 `.interview-docs/project_knowledge_graph.md` 中的决策清单
   - 读取 `{SKILL_DIR}/references/03-story-card-builder.md` 获取详细格式要求

2. **生成 STAR 故事卡**：
   - 将 TOP5 决策整理为可直接口述的 STAR 故事卡
   - 每张卡片 200–300 字，第一人称，适合口述（约 90–120 秒）

3. **写作要求**（强制执行）：
   - 语言自然口语化，避免书面体（"我当时..." 而非 "本项目旨在..."）
   - 必须包含具体细节：模块名、技术名称、数据量级
   - 结果要诚实，不虚构 KPI（未上线可说"验证了 XX 假设"）

4. **使用 Write 工具输出结果**：
   - 将故事卡写入 `.interview-docs/story_cards.md`

**STAR 格式**：
- **S（情境）**: 项目背景 + 技术约束
- **T（任务）**: 需要解决的具体技术问题
- **A（行动）**: 考虑过哪些方案 → 选了什么 → 为什么
- **R（结果）**: 效果、学到什么、如果重来怎么做

---

### 完成

使用 Bash 工具验证所有输出文件已生成：

```bash
ls -la .interview-docs/project_knowledge_graph.md .interview-docs/interview_questions.md .interview-docs/story_cards.md 2>/dev/null && echo "✅ All files generated successfully" || echo "❌ Some files missing"
```

告知用户生成了以下文件：

| 文件 | 内容 | 大小预期 |
|------|------|----------|
| `.interview-docs/extracted_decisions.md` | Session 决策提炼 | 5–50 KB |
| `.interview-docs/code_summary.md` | 代码架构摘要 | 5–10 KB |
| `.interview-docs/project_knowledge_graph.md` | 技术栈、决策清单、置信度标注 | 10–20 KB |
| `.interview-docs/interview_questions.md` | 20–30 道定制面试题（含追问和评分要点） | 15–30 KB |
| `.interview-docs/story_cards.md` | 5 张 STAR 故事卡（可直接口述） | 5–10 KB |

**后续建议**:
- 查看 `interview_questions.md` 中的面试题，确认每道题都引用了项目中的具体模块
- 使用 `story_cards.md` 中的卡片进行模拟面试练习
- 如果某些决策的置信度为 🔴 低，建议在实际面试中谨慎提及或补充更多细节

---

## 文件结构

```
interview-assistant/
├── SKILL.md              ← 本文件（skill 定义）
├── README.md             ← 详细设计文档
├── install.sh            ← curl 一键安装脚本
├── scripts/
│   ├── session-extractor.mjs  ← Step 2：三层过滤提取 session 决策对话
│   ├── code_analyzer.sh       ← Step 2：提取代码架构摘要
│   └── run.sh                 ← Step 2：编排入口
├── references/
│   ├── 01-project-knowledge-builder.md  ← Step 3 Prompt 模板
│   ├── 02-interview-generator.md         ← Step 4 Prompt 模板
│   └── 03-story-card-builder.md          ← Step 5 Prompt 模板
└── evals/
    └── evals.json        ← skill-creator 测试用例
```

---

## 边界处理

**session 数据稀少**：若 `.interview-docs/extracted_decisions.md` < 5KB，提示用户：
"Session 内容较少，知识图谱将主要依赖代码摘要，决策置信度标注为 🟡 中。
建议补充回答：项目最难的技术问题是什么？你主动做了哪些工程化决策？"

**无 git 仓库**：`code_summary.md` 中 git 历史为空，跳过该节，其余正常处理。

**session 目录不存在**：提示用户确认 Claude Code CLI 已安装并使用过
（`~/.claude/projects/` 目录需存在）。
