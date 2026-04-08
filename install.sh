#!/usr/bin/env bash
# install.sh — Interview Assistant 一键安装脚本
#
# 安装方式（一行命令）：
#   curl -fsSL https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant/install.sh | bash
#
# 安装内容：
#   ~/.interview-assistant/           — 工具脚本
#   ~/.claude/commands/interview-assistant.md  — Claude Code CLI 斜杠命令

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/dufemeng/lm-2026-learning/main/wiki/skills/interview-assistant"
INSTALL_DIR="$HOME/.claude/skills/interview-assistant"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

# ── 颜色输出 ──────────────────────────────────────────────────────────────────
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*"; }

echo ""
echo "============================================================"
echo "  Interview Assistant — 安装程序"
echo "============================================================"
echo ""

# ── 前置检查 ──────────────────────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  red "❌ 未找到 curl，请先安装 curl"
  exit 1
fi

if ! command -v node &>/dev/null; then
  yellow "⚠️  未找到 node。运行工具时需要 Node.js 18+。"
  yellow "   安装：https://nodejs.org/ 或 brew install node"
fi

# ── 创建目录 ──────────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/scripts"
mkdir -p "$INSTALL_DIR/references"
mkdir -p "$INSTALL_DIR/evals"
mkdir -p "$CLAUDE_COMMANDS_DIR"

# ── 下载脚本文件 ──────────────────────────────────────────────────────────────
echo "📥 下载脚本文件到 $INSTALL_DIR ..."

files=(
  "scripts/session-extractor.mjs"
  "scripts/code_analyzer.sh"
  "scripts/run.sh"
  "scripts/extract_decision_count.sh"
  "scripts/write_session_header.sh"
  "references/01-project-knowledge-builder.md"
  "references/02-interview-generator.md"
  "references/03-story-card-builder.md"
  "references/04-mock-interview.md"
  "SKILL.md"
)

for f in "${files[@]}"; do
  printf "  %-50s" "$f"
  curl -fsSL "$REPO_RAW/$f" -o "$INSTALL_DIR/$f"
  green "✓"
done

# 赋予脚本执行权限
chmod +x "$INSTALL_DIR/scripts/run.sh" "$INSTALL_DIR/scripts/code_analyzer.sh" \
         "$INSTALL_DIR/scripts/extract_decision_count.sh" \
         "$INSTALL_DIR/scripts/write_session_header.sh" 2>/dev/null || true

# ── 安装 Claude Code CLI 斜杠命令 ─────────────────────────────────────────────
COMMAND_FILE="$CLAUDE_COMMANDS_DIR/interview-assistant.md"

cat > "$COMMAND_FILE" << 'CLAUDE_CMD'
你是面试助手（Interview Assistant）。根据工程师的 Claude Code 开发 session 和项目代码，生成定制化面试题和 STAR 故事卡，然后直接开始模拟面试练习。

## 执行步骤

**输入参数**：`$ARGUMENTS`（项目目录路径，可选）

### Step 1 — 自动提取

```bash
bash ~/.claude/skills/interview-assistant/scripts/run.sh $ARGUMENTS
```

确认生成了 `.interview-docs/extracted_decisions.md` 和 `.interview-docs/code_summary.md`。

检查 `.interview-docs/interview_questions.md` 是否存在：
- **存在** → 询问「检测到之前的分析结果，直接开始面试还是重新分析？」
  - 选「直接开始」→ 执行 `bash ~/.claude/skills/interview-assistant/scripts/extract_decision_count.sh`，捕获 DECISION_COUNT=D，跳到 Step 3
  - 选「重新分析」→ 继续 Step 2
- **不存在** → 继续 Step 2

### Step 2 — 分析与准备

询问用户目标职级和 JD（可选），然后串行执行：

**2a** — 按照 `~/.claude/skills/interview-assistant/references/01-project-knowledge-builder.md` 的格式，交叉印证两份文档生成知识图谱，保存到 `.interview-docs/project_knowledge_graph.md`。告知「✅ 知识图谱已生成，正在生成面试题...」

**2b** — 按照 `~/.claude/skills/interview-assistant/references/02-interview-generator.md` 的格式，基于 TOP D 高价值决策生成面试题（每决策 5 道），保存到 `.interview-docs/interview_questions.md`。告知「✅ 面试题已生成，正在生成故事卡...」

**2c** — 按照 `~/.claude/skills/interview-assistant/references/03-story-card-builder.md` 的格式，生成 STAR 故事卡，保存到 `.interview-docs/story_cards.md`。告知「✅ 故事卡已生成」

**2d** — 提取决策总数：
```bash
bash ~/.claude/skills/interview-assistant/scripts/extract_decision_count.sh
```
捕获输出中的 `DECISION_COUNT=D`，告知「分析完毕，共 D 个决策，开始面试？」

### Step 3 — 模拟面试

写入会话头：
```bash
bash ~/.claude/skills/interview-assistant/scripts/write_session_header.sh
```

然后读取并严格遵守 `~/.claude/skills/interview-assistant/references/04-mock-interview.md` 中的全部规则开始面试。每个决策完成后追加评分：
```bash
bash ~/.claude/skills/interview-assistant/scripts/write_session_header.sh --append-decision --decision "决策标题" --score "评分"
```

### Step 4 — 面试总结

生成总结（总题数、评分分布、强项、需加强、复习推荐），通过 Bash heredoc 追加写入 `.interview-docs/mock_interview_summary.md`。
CLAUDE_CMD

green "✓  Claude Code 斜杠命令已安装：$COMMAND_FILE"

# ── 可选：添加 shell alias ────────────────────────────────────────────────────
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "interview-assistant" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Interview Assistant" >> "$SHELL_RC"
    echo "alias interview-assistant='bash ~/.claude/skills/interview-assistant/scripts/run.sh'" >> "$SHELL_RC"
    green "✓  Shell alias 已添加到 $SHELL_RC"
  else
    yellow "ℹ️  Shell alias 已存在，跳过"
  fi
fi

# ── 完成 ──────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
green "  ✅ 安装完成！"
echo "============================================================"
echo ""
echo "  使用方式一：Claude Code CLI 斜杠命令（推荐）"
echo "    在任意项目目录打开 Claude Code CLI，输入："
echo ""
echo "      /interview-assistant /path/to/your/project"
echo ""
echo "  使用方式二：直接运行脚本"
echo "    bash ~/.claude/skills/interview-assistant/scripts/run.sh /path/to/your/project"
echo ""
if [ -n "$SHELL_RC" ]; then
  echo "  使用方式三：Shell alias（需重启终端或 source $SHELL_RC）"
  echo "    interview-assistant /path/to/your/project"
  echo ""
fi
echo "  更新到最新版："
echo "    curl -fsSL $REPO_RAW/install.sh | bash"
echo ""
