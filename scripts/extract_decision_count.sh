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

# 匹配以 ## 开头的决策章节标题（排除 # 总标题行）
# interview_questions.md 格式：每个决策用 ## 决策N: 标题 开头
D=$(grep -c '^## ' "$QUESTIONS_FILE" 2>/dev/null || echo 0)

echo "DECISION_COUNT=$D"
