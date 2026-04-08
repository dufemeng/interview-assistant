#!/usr/bin/env bash
# extract_decision_count.sh — 从 interview_questions.md 提取决策总数
# 输出格式：DECISION_COUNT=N
# 用途：Step 2 末尾执行，结果由 SKILL.md 指令捕获并注入对话

set -euo pipefail

QUESTIONS_FILE=".interview-docs/interview_questions.md"

if [[ ! -f "$QUESTIONS_FILE" ]]; then
  echo "DECISION_COUNT=0"
  exit 0
fi

# 匹配 `### 决策 N：` 格式的章节标题（02-interview-generator.md 强制输出此格式）
# 使用精确模式避免误匹配元数据行（如 ## 目标职级：...）
D=$(grep -c '^### 决策 [0-9]' "$QUESTIONS_FILE" 2>/dev/null || echo 0)

echo "DECISION_COUNT=$D"
