# 面试助手（Interview Assistant）

基于你用 Claude Code 开发项目时留下的 session 记录和代码，生成**只有你能答的面试题**和 STAR 故事卡。不是八股题库，是锚定在你真实架构决策上的定制题目。

---

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
```

**前提**：已安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) 和 Node.js 18+。

---

## 使用

### 方式一：Claude Code CLI（推荐）

在项目目录下打开 Claude Code，输入：

```
/interview-assistant
```

不填路径时自动分析当前项目目录。分析其他目录时指定路径：

```
/interview-assistant /path/to/your/project
```

Claude 会自动完成全部步骤，无需手动复制粘贴：

1. 询问目标职级和 JD（可选）
2. 运行脚本提取 session 决策 + 代码摘要
3. 生成项目知识图谱（含置信度标注）
4. 生成 20–30 道定制面试题
5. 生成 5 张 STAR 格式故事卡

**输出文件：**

| 文件 | 内容 |
|------|------|
| `extracted_decisions.md` | Session 决策提炼（5–50 KB） |
| `code_summary.md` | 代码架构摘要（5–10 KB） |
| `project_knowledge_graph.md` | 知识图谱，含置信度标注 |
| `interview_questions.md` | 20–30 道定制面试题 |
| `story_cards.md` | 5 张 STAR 故事卡，可直接口述 |

---

### 方式二：单独运行提取脚本

只做 session 提取和代码分析（不生成面试题），适合先检查提取结果再让 Claude 处理：

```bash
# 分析当前目录
bash ~/.claude/skills/interview-assistant/scripts/run.sh

# 指定目录
bash ~/.claude/skills/interview-assistant/scripts/run.sh /path/to/your/project

# session 数据量大时缩减范围（默认 30 天 / 最多 20 个文件）
bash ~/.claude/skills/interview-assistant/scripts/run.sh /path/to/your/project --days 14 --max-files 10
```

---

## 常见情况

**session 数据很少（< 5 KB）**  
知识图谱会主要依赖代码摘要，决策置信度会偏低。可在 `extracted_decisions.md` 末尾手动补充：项目最难的技术问题、你主动做的工程化决策、最想推翻的选择。

**session 总量超过 200 MB**  
加 `--days 14 --max-files 10` 缩减范围，或只保留最活跃阶段的 session。

**没有 git 历史**  
代码摘要会跳过提交历史节，其余正常生成。

**没有 `~/.claude/projects/` 目录**  
说明 Claude Code CLI 尚未使用过，session 部分会为空，只能基于代码分析。

---

## 更新

```bash
curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
```

---

## 详细设计

架构图、组件详细设计、关键设计决策见 [DESIGN.md](DESIGN.md)。
