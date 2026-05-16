# Checklist

## 项目基础
- [ ] eval-dashboard/ 目录已创建，Next.js 项目可正常启动（`npm run dev` 无报错）
- [ ] 已安装 @anthropic-ai/sdk 依赖

## 数据层
- [ ] eval-store.ts 可正确读取和写入 evals/evals.json
- [ ] skill-loader.ts 可正确读取 SKILL.md + references/ + scripts/ 并组装为完整字符串
- [ ] types.ts 中定义了 EvalCase、EvalCriteria、EvalResult、EvalReport 等核心类型

## API 路由
- [ ] GET /api/evals 返回所有 eval 用例
- [ ] POST /api/evals 可新增 eval 用例并持久化到 evals.json
- [ ] PUT /api/evals/[id] 可更新 eval 用例
- [ ] DELETE /api/evals/[id] 可删除 eval 用例
- [ ] POST /api/evals/[id]/criteria 可调用 LLM 自动生成评测标准
- [ ] POST /api/evals/[id]/execute 可执行单个 eval 并返回结果
- [ ] POST /api/evals/execute-all 可批量执行所有已确认的 eval
- [ ] GET /api/reports 返回最新评测报告

## 执行引擎
- [ ] executor.ts 的 executeEval() 能成功调用 Anthropic API 生成 with_skill 输出（system prompt 注入 skill context）
- [ ] executor.ts 的 executeEval() 能成功调用 Anthropic API 生成 without_skill 输出（无 skill context）
- [ ] executor.ts 的 executeEval() 能使用评测标准对两组输出进行评分
- [ ] 执行结果保存到 iteration-{N}/eval-{M}/ 目录，兼容现有格式

## 前端页面
- [ ] 评测集管理页可展示所有 eval 用例卡片（名称、分类、prompt 摘要）
- [ ] 评测集管理页可新增 eval 用例（填写 prompt、expected_output、validation_criteria）
- [ ] 评测集管理页可编辑和删除 eval 用例
- [ ] 评测标准页可展示各 eval 用例的评测标准状态
- [ ] 评测标准页可自动生成评测标准（调用 LLM）
- [ ] 评测标准页可手动编辑评测标准
- [ ] 评测标准页可确认/锁定评测标准
- [ ] 执行控制台页有"开始评测"按钮，可触发批量执行
- [ ] 执行控制台页实时展示执行进度
- [ ] 评测报告页展示总体评分和各 eval 得分
- [ ] 评测报告页展示 with_skill vs without_skill 对比
- [ ] 评测报告页展示各 validation_criteria 判定结果
- [ ] 评测报告页展示 LLM 生成的改进建议

## 端到端验证
- [ ] 完整流程可走通：导入 evals.json → 生成评测标准 → 确认 → 一键执行 → 查看报告
