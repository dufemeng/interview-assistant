#!/usr/bin/env bash
# run.sh — Interview Assistant 一键执行入口
#
# 用法：
#   bash run.sh                                      # 分析当前目录
#   bash run.sh /path/to/your/project                # 位置参数
#   bash run.sh --project /path/to/your/project      # 命名参数
#   bash run.sh /path/to/your/project --days 14 --max-files 10
#
# 执行流程：
#   Step 1 — SessionExtractor: 提取 Claude Code CLI session → .interview-docs/extracted_decisions.md
#   Step 2 — CodeArchitectureAnalyzer: 分析代码结构         → .interview-docs/code_summary.md

set -euo pipefail

# ── 参数解析 ──────────────────────────────────────────────────────────────────
PROJECT_DIR=""
EXTRA_ARGS=""
# 支持 --project <path> 命名参数和位置参数两种写法
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --days|--max-files) EXTRA_ARGS="$EXTRA_ARGS $1 $2"; shift 2 ;;
    --*) shift ;;  # 忽略未知 flag
    *) [ -z "$PROJECT_DIR" ] && PROJECT_DIR="$1"; shift ;;
  esac
done
EXTRA_ARGS="${EXTRA_ARGS# }"  # 去除首部多余空格

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

# 检查项目目录参数（可选；未指定时默认使用当前工作目录）
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(pwd)"
  echo "ℹ️  未指定项目目录，使用当前目录：$PROJECT_DIR"
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ 项目目录不存在：$PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# ── 检测项目专属 session 目录 ──────────────────────────────────────────────────
# Claude Code CLI 命名规则：将项目绝对路径的 / 全部替换为 -
# 例：/Users/foo/my-app → ~/.claude/projects/-Users-foo-my-app/
PROJECT_SESSION_SUBDIR="$(echo "$PROJECT_DIR" | sed 's|/|-|g')"
PROJECT_SESSION_DIR="$HOME/.claude/projects/$PROJECT_SESSION_SUBDIR"

if [ -d "$PROJECT_SESSION_DIR" ]; then
  echo "ℹ️  检测到项目专属 session 目录：$PROJECT_SESSION_DIR"
  SESSION_DIR_OVERRIDE="$PROJECT_SESSION_DIR"
else
  echo "ℹ️  未找到项目专属 session 目录，将从 ~/.claude/projects/ 全局提取"
  SESSION_DIR_OVERRIDE=""
fi

# ── 创建输出目录并写入 .gitignore ─────────────────────────────────────────────
OUTPUT_DIR="$PROJECT_DIR/.interview-docs"
mkdir -p "$OUTPUT_DIR"

GITIGNORE="$PROJECT_DIR/.gitignore"
if ! grep -qxF '.interview-docs/' "$GITIGNORE" 2>/dev/null; then
  echo '.interview-docs/' >> "$GITIGNORE"
  echo "ℹ️  已将 .interview-docs/ 加入 $GITIGNORE"
fi

echo "📋 配置信息："
echo "   项目目录：$PROJECT_DIR"
echo "   输出目录：$OUTPUT_DIR"
echo "   脚本目录：$SCRIPT_DIR"
echo "   Node.js：$(node --version)"
echo ""

# ── Step 1：SessionExtractor ──────────────────────────────────────────────────
echo "------------------------------------------------------------"
echo "  Step 1 / 2 — SessionExtractor"
echo "  从 ~/.claude/projects/ 提取决策对话 → .interview-docs/extracted_decisions.md"
echo "------------------------------------------------------------"
echo ""

# shellcheck disable=SC2086
SESSION_DIR="$SESSION_DIR_OVERRIDE" OUTPUT_FILE="$OUTPUT_DIR/extracted_decisions.md" node "$SCRIPT_DIR/session-extractor.mjs" $EXTRA_ARGS

if [ ! -f "$OUTPUT_DIR/extracted_decisions.md" ]; then
  echo "❌ extracted_decisions.md 未生成，请检查上方错误信息"
  exit 1
fi

echo ""

# ── Step 2：CodeArchitectureAnalyzer ─────────────────────────────────────────
echo "------------------------------------------------------------"
echo "  Step 2 / 2 — CodeArchitectureAnalyzer"
echo "  分析项目代码结构 → .interview-docs/code_summary.md"
echo "------------------------------------------------------------"
echo ""

bash "$SCRIPT_DIR/code_analyzer.sh" "$PROJECT_DIR" "$OUTPUT_DIR/code_summary.md"

if [ ! -f "$OUTPUT_DIR/code_summary.md" ]; then
  echo "❌ code_summary.md 未生成，请检查上方错误信息"
  exit 1
fi

echo ""

# ── 输出统计 ──────────────────────────────────────────────────────────────────
decisions_size=$(( $(wc -c < "$OUTPUT_DIR/extracted_decisions.md") / 1024 ))
code_size=$(( $(wc -c < "$OUTPUT_DIR/code_summary.md") / 1024 ))
total_size=$(( decisions_size + code_size ))

# 检查 extracted_decisions.md 是否有内容（是否有实际消息）
decisions_has_content=false
if [ "$decisions_size" -gt 0 ]; then
  # 检查文件是否包含 "用户" 或 "Claude" 标记
  if grep -q "用户\|Claude\|human\|assistant" "$OUTPUT_DIR/extracted_decisions.md" 2>/dev/null; then
    decisions_has_content=true
  fi
fi

# 检查 code_summary.md 是否有内容
code_has_content=false
if [ "$code_size" -gt 0 ]; then
  # 检查文件是否包含关键部分
  if grep -q "Directory Structure\|Dependency Stack\|Commit History" "$OUTPUT_DIR/code_summary.md" 2>/dev/null; then
    code_has_content=true
  fi
fi

echo "============================================================"
echo "  ✅ Extraction Complete!"
echo "============================================================"
echo ""
echo "  Generated files:"
printf "    %-30s %s KB\n" ".interview-docs/extracted_decisions.md" "$decisions_size"
printf "    %-30s %s KB\n" ".interview-docs/code_summary.md" "$code_size"
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
      "path": ".interview-docs/extracted_decisions.md",
      "exists": true,
      "size_kb": $decisions_size,
      "has_content": $decisions_has_content
    },
    "code_summary": {
      "path": ".interview-docs/code_summary.md",
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
