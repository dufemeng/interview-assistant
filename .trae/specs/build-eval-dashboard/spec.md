# Skill Eval 可视化评测平台 Spec

## Why

当前 interview-assistant skill 的 eval 流程完全依赖 skill-creator 自带的 eval 功能，即手动执行 Claude Code、手动对比 `with_skill/` 和 `without_skill/` 的输出、人工判断质量。这导致：
1. 评测集和评测标准无法可视化管理和编辑
2. 每次跑 eval 需要手动操作 Claude Code，耗时且不可复现
3. 评测报告依赖人工阅读对比，缺乏量化评分和改进建议

需要一个可视化 Web 界面，替代当前手动工作流，实现评测集管理、自动化执行、量化评分的一站式 eval 平台。

## What Changes

- 新增一个 Web 应用（Next.js），提供 eval 可视化界面
- 新增后端服务，集成 Claude Code CLI 的调用能力（通过 Anthropic API 模拟 skill 执行）
- 新增评测集管理功能：支持从 `evals/evals.json` 导入 + 大模型自动生成 + 手动编辑
- 新增评测标准管理功能：支持大模型自动生成 + 手动编辑 + 确认
- 新增评测执行引擎：一键触发 Claude Code 模拟执行 skill，实时展示进度
- 新增评测报告：量化评分 + 对比分析 + 改进建议
- 新增 skill 自动安装/更新机制

## Impact

- Affected code: 新增独立的 `eval-dashboard/` 目录，不修改现有 skill 代码
- Affected specs: 复用现有 `evals/evals.json` 数据格式，扩展 `iteration-{N}/` 结果结构

## ADDED Requirements

### Requirement: Web 可视化界面

系统 SHALL 提供一个 Web 界面，包含以下页面：
1. **评测集管理页**：展示当前 `evals/evals.json` 中的所有 eval 用例，支持查看、编辑、新增、删除
2. **评测标准页**：针对每个 eval 用例，展示评测标准（大模型生成 + 手动补充），支持确认/编辑
3. **执行控制台页**：一键触发 eval 执行，实时展示执行进度和日志
4. **评测报告页**：展示评分、对比分析、改进建议

#### Scenario: 用户查看评测集
- **WHEN** 用户打开评测集管理页
- **THEN** 系统展示 `evals/evals.json` 中所有 eval 用例，以卡片/表格形式呈现，包含名称、分类、prompt 摘要、验证标准

#### Scenario: 大模型自动生成评测集
- **WHEN** 用户点击"自动生成评测集"按钮
- **THEN** 系统读取 SKILL.md 和 references/ 目录，调用 LLM 自动生成新的 eval 用例建议，用户确认后写入 `evals/evals.json`

#### Scenario: 手动新增评测集
- **WHEN** 用户点击"新增评测集"按钮并填写 prompt、预期输出、验证标准
- **THEN** 系统将新 eval 用例追加到 `evals/evals.json`

### Requirement: 评测标准管理

系统 SHALL 支持评测标准的生成、编辑和确认：
1. 大模型根据 SKILL.md 和 eval prompt 自动生成评测标准（评分维度 + 权重 + 满分描述）
2. 用户可手动补充/修改评测标准
3. 用户确认后锁定评测标准，作为后续评分依据

#### Scenario: 自动生成评测标准
- **WHEN** 用户对某个 eval 用例点击"生成评测标准"
- **THEN** 系统调用 LLM，基于 SKILL.md 和该 eval 的 prompt + expected_output，生成结构化评测标准（含评分维度、权重、每个维度的满分/扣分描述）

#### Scenario: 确认评测标准
- **WHEN** 用户审阅评测标准后点击"确认"
- **THEN** 系统锁定该评测标准，标记为"已确认"状态，后续执行 eval 时使用此标准评分

### Requirement: 评测执行引擎

系统 SHALL 提供评测执行能力：
1. 一键启动 eval 执行：在服务端调用 Anthropic API 模拟 Claude Code + skill 执行
2. 执行前自动安装/更新 skill 到最新版本
3. 实时展示执行进度（当前执行的 eval 用例、已完成数量、日志流）
4. 执行结果保存到 `iteration-{N}/eval-{M}/` 目录结构

#### Scenario: 一键执行全部 eval
- **WHEN** 用户点击"开始评测"按钮
- **THEN** 系统依次执行所有已确认评测标准的 eval 用例，对每个用例：
  1. 调用 Anthropic API，以 skill 的 prompt 作为用户输入
  2. 在 system prompt 中注入 SKILL.md 全文 + references/ 内容（模拟 skill 安装）
  3. 收集 API 返回的完整响应作为"with_skill"输出
  4. 不注入 skill 内容，仅用原始 prompt 调用 API，收集"without_skill"输出
  5. 使用已确认的评测标准对两组输出进行评分
  6. 保存结果到对应目录

#### Scenario: 执行单个 eval
- **WHEN** 用户对某个 eval 用例点击"单独执行"
- **THEN** 系统仅执行该 eval 用例，流程同上

### Requirement: 评测报告

系统 SHALL 在执行完成后生成评测报告：
1. 总体评分（百分制）+ 各维度评分
2. with_skill vs without_skill 对比分析
3. 每个 validation_criteria 的通过/失败状态
4. LLM 生成的改进建议（针对 skill 的 SKILL.md、references、scripts）

#### Scenario: 查看评测报告
- **WHEN** 用户打开评测报告页
- **THEN** 系统展示最新一轮 eval 的完整报告，包含：
  - 总分 + 各 eval 用例得分
  - 每个用例的 with_skill/without_skill 输出对比
  - 每个 validation_criteria 的判定结果（通过/失败 + 原因）
  - LLM 生成的改进建议（按优先级排序）

### Requirement: Skill 自动安装/更新

系统 SHALL 在每次执行 eval 前自动确保 skill 为最新版本：
1. 读取当前 skill 目录的 SKILL.md、references/、scripts/
2. 将最新内容注入到 API 调用的 system prompt 中

#### Scenario: Skill 内容注入
- **WHEN** eval 执行开始
- **THEN** 系统读取 skill 目录下所有文件，构建完整的 skill context，注入到 Anthropic API 的 system prompt 中

## MODIFIED Requirements

（无修改，本次为纯新增）

## REMOVED Requirements

（无移除）
