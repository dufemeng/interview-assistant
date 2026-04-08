#!/usr/bin/env bash
# write_session_header.sh — 写入面试会话头时间戳 / 追加决策评分记录
#
# 用法：
#   写入会话头（Step 3 开始时）：
#     bash write_session_header.sh
#
#   追加决策评分（每个决策完成后）：
#     bash write_session_header.sh --append-decision --decision "决策标题" --score "A×1/B×1/C×0"

set -euo pipefail

SUMMARY_FILE=".interview-docs/mock_interview_summary.md"

# 确保目录存在
mkdir -p ".interview-docs"

MODE="header"
DECISION=""
SCORE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --append-decision) MODE="decision"; shift ;;
    --decision) DECISION="$2"; shift 2 ;;
    --score) SCORE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ "$MODE" == "header" ]]; then
  # 写入会话分隔头，包含精确时间戳
  printf "\n---\n### 面试记录 %s\n\n" "$(date '+%Y-%m-%d %H:%M')" >> "$SUMMARY_FILE"
elif [[ "$MODE" == "decision" ]]; then
  # 追加单个决策的评分记录
  printf "**%s**：%s\n" "$DECISION" "$SCORE" >> "$SUMMARY_FILE"
fi
