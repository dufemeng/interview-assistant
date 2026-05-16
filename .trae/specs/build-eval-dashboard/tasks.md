# Tasks

## MVP 范围说明

MVP 目标：替代当前手动 eval 工作流，实现「导入评测集 → 生成/编辑评测标准 → 一键执行 → 查看评分报告」的完整闭环。

技术选型：Next.js (App Router) + TypeScript + Tailwind CSS + Anthropic SDK（直接调用 API 模拟 skill 执行，不依赖 Claude Code CLI 进程）

---

- [ ] Task 1: 项目脚手架搭建 — 创建 eval-dashboard/ 目录，初始化 Next.js 项目
  - [ ] SubTask 1.1: 在 interview-assistant 根目录下创建 `eval-dashboard/` 目录，运行 `npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --no-import-alias` 初始化
  - [ ] SubTask 1.2: 安装依赖：`@anthropic-ai/sdk`、`uuid`
  - [ ] SubTask 1.3: 创建基础目录结构：`src/app/`（页面）、`src/lib/`（核心逻辑）、`src/components/`（UI 组件）

- [ ] Task 2: 核心数据层 — 读取/写入 evals.json 和 skill 文件的工具函数
  - [ ] SubTask 2.1: 创建 `src/lib/eval-store.ts`：封装对 `../evals/evals.json` 的读写操作（读取所有 eval、新增 eval、更新 eval、删除 eval）
  - [ ] SubTask 2.2: 创建 `src/lib/skill-loader.ts`：读取 SKILL.md、references/ 目录下所有 .md 文件、scripts/ 目录下所有文件，组装为完整 skill context 字符串
  - [ ] SubTask 2.3: 创建 `src/lib/types.ts`：定义核心 TypeScript 类型（EvalCase、EvalCriteria、EvalResult、EvalReport）

- [ ] Task 3: API 路由 — eval 管理 + 执行 + 报告的后端接口
  - [ ] SubTask 3.1: `src/app/api/evals/route.ts` — GET 返回所有 eval 用例，POST 新增 eval 用例
  - [ ] SubTask 3.2: `src/app/api/evals/[id]/route.ts` — GET/PUT/DELETE 单个 eval 用例
  - [ ] SubTask 3.3: `src/app/api/evals/[id]/criteria/route.ts` — POST 调用 LLM 自动生成评测标准，PUT 保存用户编辑后的评测标准
  - [ ] SubTask 3.4: `src/app/api/evals/[id]/execute/route.ts` — POST 触发单个 eval 执行（调用 Anthropic API 模拟 with_skill 和 without_skill，使用评测标准评分）
  - [ ] SubTask 3.5: `src/app/api/evals/execute-all/route.ts` — POST 批量执行所有已确认评测标准的 eval
  - [ ] SubTask 3.6: `src/app/api/reports/route.ts` — GET 返回最新一轮评测报告

- [ ] Task 4: 评测执行引擎 — 核心逻辑实现
  - [ ] SubTask 4.1: 创建 `src/lib/executor.ts`：实现 `executeEval()` 函数，流程为：
    1. 调用 Anthropic API（system prompt 注入 skill context）→ with_skill 输出
    2. 调用 Anthropic API（无 skill context）→ without_skill 输出
    3. 调用 Anthropic API（传入评测标准 + 两组输出）→ 评分结果
  - [ ] SubTask 4.2: 创建 `src/lib/report-generator.ts`：汇总所有 eval 执行结果，调用 LLM 生成改进建议，组装完整报告
  - [ ] SubTask 4.3: 结果持久化：将执行结果保存到 `../iteration-{N}/eval-{M}/` 目录结构（兼容现有格式）

- [ ] Task 5: 前端页面 — 评测集管理页
  - [ ] SubTask 5.1: `src/app/page.tsx` — 首页/评测集管理页，展示 evals.json 中所有 eval 用例的卡片列表（名称、分类、prompt 摘要）
  - [ ] SubTask 5.2: 支持新增 eval 用例的表单（prompt、expected_output、validation_criteria、category）
  - [ ] SubTask 5.3: 支持编辑和删除 eval 用例

- [ ] Task 6: 前端页面 — 评测标准页
  - [ ] SubTask 6.1: `src/app/criteria/page.tsx` — 评测标准管理页，展示所有 eval 用例的评测标准状态（未生成/已生成/已确认）
  - [ ] SubTask 6.2: "自动生成"按钮：调用 LLM 为选中 eval 生成评测标准（评分维度、权重、满分描述）
  - [ ] SubTask 6.3: 评测标准编辑器：支持手动修改各维度的权重和描述
  - [ ] SubTask 6.4: "确认"按钮：锁定评测标准，标记为已确认

- [ ] Task 7: 前端页面 — 执行控制台 + 评测报告页
  - [ ] SubTask 7.1: `src/app/execute/page.tsx` — 执行控制台页：展示所有已确认 eval 用例的执行状态，"开始评测"按钮触发批量执行，实时显示进度（当前执行到第几个/总共几个，每个 eval 的状态：等待中/执行中/已完成/失败）
  - [ ] SubTask 7.2: `src/app/reports/page.tsx` — 评测报告页：展示总体评分、各 eval 得分、with_skill vs without_skill 对比、各 validation_criteria 判定结果、LLM 改进建议

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 2]
- [Task 5] depends on [Task 3]
- [Task 6] depends on [Task 3]
- [Task 7] depends on [Task 3, Task 4]
- Task 5, 6, 7 可并行开发
