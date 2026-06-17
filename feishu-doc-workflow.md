---
name: feishu-doc-workflow
description: 飞书文档迁移最佳实践 — 内容完整性优先、限流处理、账号选择
metadata:
  type: feedback
---

## 核心原则：内容完整性绝不可妥协

将 Markdown 文档迁移为飞书云文档时，所有内容元素（表格每一行、图中每一个子模块子项）必须100%保留。**绝不允许为了规避技术问题（语法错误、限流）而删减内容。**

**Why:** 用户明确要求画板和图片必须严格一致，不可变化一点。

**How to apply:**
- PlantUML 语法报错 → 修正语法，不删内容（参考 [[feishu-plantuml-rules]]）
- API 限流 → 加延迟重试，不跳过块
- 单个 board 太复杂 → 拆分为多个 board，每个都保留完整子元素

## 限流处理

飞书 API 在快速连续调用时会返回 `code: 99991400`（frequency limit）。

处理方式：
1. 每次 `_add_children` 调用间加 0.3s 延迟
2. 遇到 99991400 时指数退避重试（2s、4s、6s...）
3. 在 run.py 中 monkey-patch `FeishuDoc._post` 和 `_add_children`

## 账号选择逻辑

参考 [[feishu-accounts]]：
- 用户指定手机号 18519038770 或个人账号 → 用 `personal` (cli_a924857989f81bc0)
- 涉及小米企业内容 → 用 `xiaomi` (cli_a97ad95531251cd4)
- `personal` 账号有 `board:whiteboard:node:create` 和 `contact:user.id:readonly` 权限
- `xiaomi` 账号缺少 contact 权限，无法通过手机号转移所有权

## 飞书文档读取铁律：必须用浏览器浏览，不能直接调 API

**用户明确指令**："读取文档不能用API, 而是用浏览器浏览"

**How to apply:**
- 提取飞书文档内容时：浏览器 `page.goto(/docx/{token})` → 监听 XHR → 获取 CLIENT_VARS 格式 block_map
- 如果 XHR 未捕获（Service Worker 缓存）：`page.evaluate` 执行 XHR 调用 client_vars API（WITH browser cookies）
- **绝对不允许**：从 Python 直接调用 `client_vars` API（没有 browser auth 会返回 4000003）

## Wiki 文档 Token 处理规范

**关键原则：wiki 知识库里的文档，存储 token 一定是 wiki_token，不是 docx token**

- `doc_enumerator.py` 的 `_enumerate_wiki_space()` 对 obj_type=22 节点：存 `doc_type="wiki"` 而不是 "docx"
- runner 处理 wiki type 文档时必须先 `_resolve_wiki_token(wiki_token)` → 得到 `(obj_token, obj_type)` → 导航 `/docx/{obj_token}`
- **数据修复 SQL**（遇到 wiki 来源的 docx 文档全部 4000003 时使用）：
  ```sql
  UPDATE documents SET doc_type='wiki' WHERE status IN ('pending','failed') AND doc_type='docx' AND source LIKE 'wiki:%'
  ```
- 详细：见项目记忆 `wiki-url-fix.md` 和 `wiki-docx-type-bug.md`

## ASCII 图转 PlantUML 的原则

1. 每个 ASCII 框图中的**每一个方框**都必须转为 PlantUML 中的一个节点/组件
2. 框内列出的子项也必须全部保留为子节点
3. 优先使用：`package` 嵌套（架构图）、`@startmindmap`（层级树）、活动图（流程）
4. 不要因为节点多就精简 — 飞书测试通过了 30+ 个 package 嵌套无问题
