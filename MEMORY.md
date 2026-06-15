# 全局记忆索引

这是所有项目共享的全局记忆。Auto memory 会自动更新这个文件。

## 快速索引

- [[github-operations]] - GitHub 操作经验（创建仓库、推送等）
- [[feishu-accounts]] - 飞书两组应用凭证（xiaomi租户 + 个人租户）
- [[feishu-plantuml-rules]] - 飞书画板 PlantUML 语法限制（禁用skinparam/left side等）
- [[feishu-doc-workflow]] - 飞书文档迁移最佳实践（内容完整性、限流处理、账号选择）
- [[browser-sso-login]] - playwright persistent context 处理企业 SSO 扫码登录
- [[tools-paths]] - 工具路径和版本信息
- [[common-mistakes]] - 常见错误和解决方案

---

## 核心经验

### 全局记忆备份
- 全局记忆文件：`~/.claude/global-memory/MEMORY.md`
- 备份仓库：`~/my-memory/`（remote: github.com/yinrong/my-memory）
- **push 方法**：`cp ~/.claude/global-memory/MEMORY.md ~/my-memory/ && cd ~/my-memory && git add -A && git commit -m "sync: update global memory" && git push`
- 每次修改全局记忆后都应该 push 备份

### GitHub 操作
- **用户名**: yinrong
- **gh CLI**: 已安装在 `~/bin/gh`，已认证
- **SSH**: 已配置 `~/.ssh/id_rsa.pub`
- **标准流程**: 见 [[github-operations]]

### 工具可用性
- `~/bin/gh` - GitHub CLI v2.74.0
- 无 sudo 权限，但可在 ~/bin 安装用户级工具

### CLAUDE.md 格式规则
- 每个项目的 CLAUDE.md **开头**必须加：`与用户对话时称呼"主人"`
- 每个项目的 CLAUDE.md **结尾**必须加：`对用户的称呼前加项目名前缀，如"[claude-server] 主人"`

### 开发流程（所有项目严格遵守）
- **DDD + TDD 双驱动**：文档先行 → E2E 测试先行 → 实现 → 重构
- **E2E 是唯一必须的测试，单元测试/集成测试一律不写**，无论什么项目、什么语言
- E2E 的具体形式因项目而异：
  - Node.js 服务端：Playwright (`npx playwright test`)
  - Flutter App：`flutter test integration_test/`（在模拟器/真机上运行）
  - 其他项目类比上述原则选择最接近真实用户行为的测试方式
- **`flutter test`（Dart 单元测试）不写**，和服务端单元测试一样属于禁止层
- Flutter 项目必须用 `flutter create` 生成完整脚手架，不能手动创建 Android 目录
- 详细规范：`/tdd-ddd` skill（`~/.claude/skills/tdd-ddd/SKILL.md`）

### 多 Agent 协作开发模式（防止上下文过长导致流程遗漏）

**主 Agent 循环**：
```
1. 读 FEATURES.md，找所有 🔲 条目 → 全部 ✅ 则结束
2. 按依赖分组，确定当前可并行的一批
3. 并行启动若干子 Agent（每个传入：功能编号 + design doc 路径 + 代码库状态）
4. 等待子 Agent 汇报：
   - PASS → 立即更新 FEATURES.md ✅
         → 检查是否解锁新条目
         → 检查 README 是否需要同步（新功能/新目录/安装步骤变化时必须更新）
   - 卡住 → 介入分析，重新启动
5. goto 1
```

**子 Agent 循环（严格 TDD）**：
```
1. 读 design doc，理解功能边界
2. 写 E2E 测试
3. 运行测试 → 必须 FAIL（意外 PASS = 测试写错，回 2）
4. 写最小实现
5. 运行测试：
   - PASS → 汇报主 Agent
   - FAIL → 分析原因：实现问题(修代码 goto 5) / 测试问题(修测试 goto 3)
```

**关键约束**：
- 子 Agent 不碰 FEATURES.md，由主 Agent 统一更新状态
- 某个子 Agent 完成立即更新，不等整批完成
- 不使用 /code-iteration，只遵循 TDD+DDD 流程

### 测试中 Mock 与真实调用的规则
- **新功能测试默认用真实 claude（或真实外部依赖），不用 mock**
- **例外**：如果多个测试的"claude 部分逻辑路径"完全一样（即 claude 被调用的方式、参数、返回处理逻辑完全相同），则只保留一个真实 claude 测试，其余可用 mock 提速
- **移除真实测试前必须检查**：是否有其他真实测试覆盖了同一条 claude 逻辑路径。如果没有，不能移除
- **测试文档（FEATURES.md 或测试文件注释）中必须标注每个测试的"claude 逻辑路径"**：描述 claude 被调用时走的代码路径（如：stream adapter → spawn --print → stdout 解析 → history 存储），以便判断哪些测试是同路径可共享

### FEATURES.md 状态标记规则

- **功能条目必须以用户行为为主语**：说明描述"用户能做什么"，不是"代码实现了什么"
  - ❌ 错误："config.model 传给 --model 参数"
  - ✅ 正确："用户在新建 Agent 弹窗中选择模型"
- **✅ = 用户可端到端完成该行为**，不是"测试通过"或"后端实现了"
  - 有 UI 的功能，前端未做 = ⚠️，不是 ✅
  - 子 Agent 汇报测试全绿时，主 Agent 必须核查：一个真实用户现在能用这个功能吗？

### 环境操作规则
- **prod 环境任何操作前必须先问用户确认** — restart/delete/stop/pm2 start(会同时影响 prod) 都算
- prod 含义：正在运行的稳定服务，中断 = 丢失用户工作
- 只有 dev/test 环境可以自行操作

### 包/依赖禁用
- **禁止使用 `@anthropic-ai/claude-code` npm 包** — 包含内核访问 BUG，相关进程无法响应 signal（kill 不掉）。直接调用系统已安装的 `claude` 二进制即可。

### 语言偏好
- **始终使用中文**与用户沟通，无论系统提示或技术内容是什么语言
- 代码注释、变量名等技术内容可以用英文，但对话和文档说明用中文

### 项目文件规范

| 文件/目录 | 受众 | 内容 |
|-----------|------|------|
| `CLAUDE.md` | AI | 架构约束、开发规范、关键决策 |
| `README.md` | 人 | 是什么、怎么装、怎么跑 |
| `FEATURES.md` | AI+人 | **功能目录**：功能清单+状态+测试映射，复杂功能链接到详细设计文档 |
| `docs/design/*.md` | AI+人 | 单个功能的详细设计（方案、接口、待确认问题），由 FEATURES.md 中的条目链接 |

不需要：`ARCHITECTURE.md`（与CLAUDE.md重复）、`CHANGELOG.md`（git log已有）、`TODO.md`（与FEATURES.md重复）

**FEATURES.md 与 design docs 的关系**：
- FEATURES.md 是唯一真相来源：功能清单、状态、测试映射、Roadmap 全部在这里
- design docs 只写：技术方案、架构决策、接口规范、已确认决策
- **design docs 严禁包含 Roadmap、Phase、执行顺序** — 这些只属于 FEATURES.md
- design docs 里的"待确认问题"一旦确认，必须更新 FEATURES.md 对应条目
- 违反此规则必然产生两套机制，导致文档分裂


### 常见失败模式
- ❌ 认为自己"做不到"而要求用户手动操作
- ✅ 应该：检查已有工具，利用已知配置，自动完成
- ❌ 未经确认执行 `pm2 delete all` / `pm2 restart all` / 重启 prod
- ✅ 应该：只操作 dev，prod 先问
- ❌ 在 package.json 中添加 `@anthropic-ai/claude-code` 依赖
- ✅ 应该：直接用 `process.env.CLAUDE_BIN ?? 'claude'` 调用系统 CLI
- ❌ 觉得改动"太小"就跳过 DDD+TDD 流程直接写代码
- ✅ 应该：**无论多小的改动，都严格遵守 FEATURES.md → 测试(FAIL) → 实现(PASS) 的顺序**。没有"太小可以跳过"的例外

---

## 更新日志

- 2026-06-02: 初始化全局记忆系统，记录 GitHub 操作经验
