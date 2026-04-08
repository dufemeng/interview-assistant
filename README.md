# 面试助手（Interview Assistant）

基于你用 Claude Code 开发项目时留下的 session 记录和代码，直接开始**交互式模拟面试**——Claude 扮演面试官逐题提问，你回答后立即获得评分、改进建议和完美答案。不是生成一堆文件让你自己复习，而是直接练起来。

---

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
```

**前提**：已安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) 和 Node.js 18+。

---

## 使用

在项目目录下打开 Claude Code，输入：

```
/interview-assistant
```

不填路径时自动分析当前项目目录。分析其他目录时指定路径：

```
/interview-assistant /path/to/your/project
```

整个过程分 4 步，Claude 全程驱动：

1. **自动提取**：运行脚本提取 session 决策 + 代码摘要
2. **分析与准备**：询问目标职级和 JD → 生成知识图谱、定制面试题、STAR 故事卡
3. **模拟面试**：Claude 扮演面试官逐题提问 → 你回答 → 立即评分（A/B/C）+ 反馈 + 完美答案
4. **面试总结**：强项分析 + 需要加强的点 + 指向具体文件的复习推荐

**再次练习时**：直接开始，Claude 检测到已有分析结果，跳过 Step 2 直接进入面试。

---

## 输出文件

所有文件输出到项目的 `.interview-docs/` 目录（已自动加入 `.gitignore`）：

| 文件 | 生成时机 | 内容 |
|------|----------|------|
| `extracted_decisions.md` | Step 1（脚本） | Session 决策提炼 |
| `code_summary.md` | Step 1（脚本） | 代码架构摘要 |
| `project_knowledge_graph.md` | Step 2 | 知识图谱，含置信度标注 |
| `interview_questions.md` | Step 2 | 定制面试题 + 评分要点 |
| `story_cards.md` | Step 2 | STAR 故事卡，可直接口述 |
| `mock_interview_summary.md` | Step 3（增量写入）| 每次面试的评分记录 + 总结 |

---

## 常见情况

**session 数据很少（< 5 KB）**  
知识图谱主要依赖代码摘要，决策置信度会偏低。

**session 总量超过 200 MB**  
运行脚本时加参数缩减范围：
```bash
bash ~/.claude/skills/interview-assistant/scripts/run.sh /path/to/project --days 14 --max-files 10
```

**没有 git 历史 / 没有 `~/.claude/projects/` 目录**  
代码摘要跳过 git 历史节，session 为空时只基于代码分析，其余正常运行。

---

## 更新

```bash
curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
```

