#!/usr/bin/env bash
# run.sh — Interview Assistant 一键执行入口
#
# 用法：
#   bash run.sh /path/to/your/project
#   bash run.sh /path/to/your/project --days 14 --max-files 10
#
# 执行流程：
#   Step 1 — SessionExtractor: 提取 Claude Code CLI session → extracted_decisions.md
#   Step 2 — CodeArchitectureAnalyzer: 分析代码结构     → code_summary.md
#   Step 3 — 打印后续 LLM 步骤指引

set -euo pipefail

# ── 参数解析 ──────────────────────────────────────────────────────────────────
PROJECT_DIR="${1:-}"
EXTRA_ARGS="${*:2}"   # 透传给 session-extractor.mjs 的额外参数（--days / --max-files）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 前置检查 ──────────────────────────────────────────────────────────────────
echo "============================================================"
echo "  Interview Assistant — 面试助手"
echo "============================================================"
echo ""

# 检查 Node.js
if ! command -v node &>/dev/null; then
  echo "❌ 未找到 node。请先安装 Node.js 18+：https://nodejs.org/"
  exit 1
fi

NODE_MAJOR=$(node --version | cut -d. -f1 | tr -d 'v')
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo "❌ Node.js 版本过低（当前 $(node --version)），需要 18+。"
  exit 1
fi

# 检查项目目录参数
if [ -z "$PROJECT_DIR" ]; then
  echo "用法：bash run.sh /path/to/your/project [--days <N>] [--max-files <N>]"
  echo ""
  echo "示例："
  echo "  bash run.sh ~/projects/my-video-agent"
  echo "  bash run.sh ~/projects/my-video-agent --days 14 --max-files 10"
  exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ 项目目录不存在：$PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo "📋 配置信息："
echo "   项目目录：$PROJECT_DIR"
echo "   脚本目录：$SCRIPT_DIR"
echo "   Node.js：$(node --version)"
echo ""

# ── Step 1：SessionExtractor ──────────────────────────────────────────────────
echo "------------------------------------------------------------"
echo "  Step 1 / 2 — SessionExtractor"
echo "  从 ~/.claude/projects/ 提取决策对话 → extracted_decisions.md"
echo "------------------------------------------------------------"
echo ""

# shellcheck disable=SC2086
node "$SCRIPT_DIR/session-extractor.mjs" $EXTRA_ARGS

if [ ! -f "extracted_decisions.md" ]; then
  echo "❌ extracted_decisions.md 未生成，请检查上方错误信息"
  exit 1
fi

echo ""

# ── Step 2：CodeArchitectureAnalyzer ─────────────────────────────────────────
echo "------------------------------------------------------------"
echo "  Step 2 / 2 — CodeArchitectureAnalyzer"
echo "  分析项目代码结构 → code_summary.md"
echo "------------------------------------------------------------"
echo ""

bash "$SCRIPT_DIR/code_analyzer.sh" "$PROJECT_DIR"

if [ ! -f "code_summary.md" ]; then
  echo "❌ code_summary.md 未生成，请检查上方错误信息"
  exit 1
fi

echo ""

# ── 输出统计 ──────────────────────────────────────────────────────────────────
decisions_size=$(( $(wc -c < extracted_decisions.md) / 1024 ))
code_size=$(( $(wc -c < code_summary.md) / 1024 ))
total_size=$(( decisions_size + code_size ))

# 检查 extracted_decisions.md 是否有内容（是否有实际消息）
decisions_has_content=false
if [ "$decisions_size" -gt 0 ]; then
  # 检查文件是否包含 "用户" 或 "Claude" 标记
  if grep -q "用户\|Claude\|human\|assistant" extracted_decisions.md 2>/dev/null; then
    decisions_has_content=true
  fi
fi

# 检查 code_summary.md 是否有内容
code_has_content=false
if [ "$code_size" -gt 0 ]; then
  # 检查文件是否包含关键部分
  if grep -q "Directory Structure\|Dependency Stack\|Commit History" code_summary.md 2>/dev/null; then
    code_has_content=true
  fi
fi

echo "============================================================"
echo "  ✅ Extraction Complete!"
echo "============================================================"
echo ""
echo "  Generated files:"
printf "    %-30s %s KB\n" "extracted_decisions.md" "$decisions_size"
printf "    %-30s %s KB\n" "code_summary.md" "$code_size"
echo "                                     ──────"
printf "    %-30s %s KB (LLM input)\n" "Total" "$total_size"
echo ""

# 警告提示
if [ "$total_size" -gt 80 ]; then
  echo "  ⚠️  Total exceeds 80KB. Consider:"
  echo "     bash run.sh $PROJECT_DIR --days 14 --max-files 10"
  echo ""
fi

if [ "$decisions_size" -lt 5 ]; then
  echo "  ⚠️  Session data is sparse. Knowledge graph will rely mainly on code analysis."
  echo ""
fi

# ── 输出 JSON 结果供 Claude 解析 ──────────────────────────────────────────────
echo ""
echo "------------------------------------------------------------"
echo "  JSON Result (for Claude parsing)"
echo "------------------------------------------------------------"
echo ""

# 构建 JSON 输出
cat << EOF
{
  "status": "success",
  "project_dir": "$PROJECT_DIR",
  "files": {
    "extracted_decisions": {
      "path": "extracted_decisions.md",
      "exists": true,
      "size_kb": $decisions_size,
      "has_content": $decisions_has_content
    },
    "code_summary": {
      "path": "code_summary.md",
      "exists": true,
      "size_kb": $code_size,
      "has_content": $code_has_content
    }
  },
  "total_size_kb": $total_size,
  "warnings": {
    "large_context": $([ "$total_size" -gt 80 ] && echo "true" || echo "false"),
    "sparse_session": $([ "$decisions_size" -lt 5 ] && echo "true" || echo "false")
  },
  "next_steps": "Claude will now auto-execute Step 3-5 using Read tool"
}
EOF

echo ""
echo "============================================================"
