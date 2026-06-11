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
- **E2E 是唯一必须的测试**，单元测试可省略
- 详细规范：`/tdd-ddd` skill（`~/.claude/skills/tdd-ddd/SKILL.md`）

### 多 Agent 协作开发模式（防止上下文过长导致流程遗漏）
- **主 agent**：监控状态、更新 FEATURES.md 文档状态、协调各子 agent
- **文档 agent**：写详细设计文档和测试用例
- **实现 agent**：按文档实现代码
- **测试 agent**：运行测试、报告结果
- **关键约束**：每个 agent 只负责自己的职责，主 agent 必须在子 agent 完成后立即更新 FEATURES.md 状态（🔲→✅），然后再提交。不能让实现 agent 负责更新文档——它上下文太长会遗漏

### 测试中 Mock 与真实调用的规则
- **新功能测试默认用真实 claude（或真实外部依赖），不用 mock**
- **例外**：如果多个测试的"claude 部分逻辑路径"完全一样（即 claude 被调用的方式、参数、返回处理逻辑完全相同），则只保留一个真实 claude 测试，其余可用 mock 提速
- **移除真实测试前必须检查**：是否有其他真实测试覆盖了同一条 claude 逻辑路径。如果没有，不能移除
- **测试文档（FEATURES.md 或测试文件注释）中必须标注每个测试的"claude 逻辑路径"**：描述 claude 被调用时走的代码路径（如：stream adapter → spawn --print → stdout 解析 → history 存储），以便判断哪些测试是同路径可共享

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
- FEATURES.md 是目录，每个功能条目可以链接到 `docs/design/xxx.md`
- design docs 是详细规范，但**结论必须同步回 FEATURES.md 的状态列**
- 两者不能分裂：design docs 里的"待确认问题"一旦确认，必须更新 FEATURES.md 对应条目

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
