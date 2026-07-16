# My Memory - Claude Code / Codex 全局记忆（Git 同步）

将 AI 编程工具的长期记忆沉淀到本 Git 仓库，实现跨会话、跨主机的记忆持久化与同步。

本仓库的核心原则：

- `MEMORY.md` 是人可读、可审查、可 Git 同步的共享记忆入口。
- Claude Code 可以直接把自己的全局记忆文件或记忆目录指向本仓库。
- Codex 不应直接同步自动生成的本地 memories；需要长期稳定生效的规则应整理进 `AGENTS.md`。
- 任何包含 token、密码、cookie、私钥、客户数据的内容都不要提交到本仓库，必要时只提交加密文件。

---

## Claude Code 与 Codex 如何使用本仓库

| 场景 | Claude Code | Codex |
| --- | --- | --- |
| 下载 | `git clone git@github.com:yinrong/my-memory.git ~/my-memory` | 同左 |
| 主要入口 | `~/my-memory/MEMORY.md` | 推荐 `~/my-memory/codex/AGENTS.md`，也可从 `MEMORY.md` 提炼 |
| 自动加载方式 | 将 Claude Code 的全局记忆文件/目录 symlink 到本仓库 | 将 `~/.codex/AGENTS.md` symlink 到仓库中的 Codex 指令文件 |
| 自动记忆 | Claude Code 的 auto memory 可以直接写入被 symlink 的文件/目录 | Codex memories 是本机生成状态，默认不提交；稳定规则写入 `AGENTS.md` |
| 更新 | Claude Code 修改记忆后，在本仓库 commit | Codex 侧先把有价值的经验整理进 `codex/AGENTS.md`，再 commit |
| 上传 | `git pull --rebase` 后 `git push` | 同左 |
| 冲突处理 | 合并 `MEMORY.md`，保留互补经验，删除重复项 | 合并 `codex/AGENTS.md`，只保留明确、稳定、可执行的规则 |

### Claude Code：下载、利用、更新、上传

#### 1. 下载

```bash
git clone git@github.com:yinrong/my-memory.git ~/my-memory
```

#### 2. 利用本仓库作为全局记忆

本仓库目前以 `MEMORY.md` 作为全局记忆入口。优先使用 Claude Code 全局记忆路径：

```bash
mkdir -p ~/.claude/global-memory

# 如果已经有旧文件，先备份再建立链接
mv ~/.claude/global-memory/MEMORY.md ~/.claude/global-memory/MEMORY.md.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null || true
ln -s ~/my-memory/MEMORY.md ~/.claude/global-memory/MEMORY.md
```

如果你仍在使用 Claude Code 的项目级 auto memory 目录约定，也可以把对应项目目录下的 `memory/` 指向本仓库：

```bash
mkdir -p ~/.claude/projects/-home-ubuntu
rm -rf ~/.claude/projects/-home-ubuntu/memory
ln -s ~/my-memory ~/.claude/projects/-home-ubuntu/memory
```

#### 3. 更新并上传

如果使用 symlink，Claude Code 写入全局记忆后，本仓库会直接出现文件变化：

```bash
cd ~/my-memory
git status
git pull --rebase
git add -A
git commit -m "sync: update claude memory"
git push
```

如果没有使用 symlink，先手动复制再提交：

```bash
cp ~/.claude/global-memory/MEMORY.md ~/my-memory/MEMORY.md
cd ~/my-memory
git pull --rebase
git add MEMORY.md
git commit -m "sync: update claude memory"
git push
```

#### 4. 冲突处理

`git pull --rebase` 出现冲突时，优先按语义合并，而不是简单选择某一边：

- 两边都是新增经验：都保留，放到合适标题下。
- 同一规则表达重复：保留更短、更明确的一条。
- 同一规则互相矛盾：保留最新确认过的规则，并加一句适用条件。
- 涉及账号、token、密码、cookie、私钥：不要提交明文，改成“凭证保存在本机某安全位置”的描述。

解决后执行：

```bash
git add MEMORY.md
git rebase --continue
git push
```

### Codex：下载、利用、更新、上传

Codex 的官方建议是：`AGENTS.md` 承载每次都必须遵守的稳定指令，memories 只作为辅助回忆层。也就是说，本仓库对 Codex 最适合作为“人工维护的长期规则仓库”，而不是直接同步 Codex 自动生成的本地 memory 状态。

#### 1. 下载

```bash
git clone git@github.com:yinrong/my-memory.git ~/my-memory
```

#### 2. 利用本仓库作为 Codex 全局指令

推荐在仓库里单独维护 Codex 指令文件，再链接到 Codex home：

```bash
mkdir -p ~/my-memory/codex ~/.codex

# 第一次使用时，可以从 MEMORY.md 提炼一份 Codex 版本
cp ~/my-memory/MEMORY.md ~/my-memory/codex/AGENTS.md

# 让 Codex 在任何项目中自动加载这份全局指令
ln -s ~/my-memory/codex/AGENTS.md ~/.codex/AGENTS.md
```

之后需要长期生效的偏好、开发流程、禁用项、验收标准，都写入：

```text
~/my-memory/codex/AGENTS.md
```

项目专属规则仍应写在具体项目仓库的 `AGENTS.md`，不要塞进全局文件。

#### 3. 启用 Codex 自动 memories（可选）

Codex 的自动 memories 是本机生成状态，用来帮助回忆上下文。它适合“辅助想起”，不适合当成必须遵守的规则来源。

在 `~/.codex/config.toml` 中开启：

```toml
[features]
memories = true

[memories]
generate_memories = true
use_memories = true
```

也可以在 Codex 桌面端设置里打开 memories，或在任务中使用 `/memories` 控制当前任务是否读取/生成 memories。

不要把 Codex 自动生成的本地 memories 目录或数据库直接提交到这个仓库。需要跨机器稳定复用的内容，先人工审查、去掉敏感信息，再整理进 `codex/AGENTS.md` 或 `MEMORY.md`。

#### 4. 更新并上传

Codex 侧推荐的同步节奏：

```bash
cd ~/my-memory
git pull --rebase

# 编辑 codex/AGENTS.md：只加入稳定、明确、可执行的规则
git add codex/AGENTS.md README.md MEMORY.md
git commit -m "sync: update codex memory"
git push
```

如果某条经验同时适用于 Claude Code 和 Codex：

- 写入 `MEMORY.md`，作为共享记忆。
- 再把“必须执行”的部分提炼到 `codex/AGENTS.md`。

如果只适用于 Codex：

- 写入 `codex/AGENTS.md`。

如果只是一次任务的临时背景：

- 不写入本仓库，留在当前对话上下文即可。

#### 5. 冲突处理

Codex 的冲突处理重点是避免全局指令膨胀：

- 两边都新增规则：只保留会反复影响未来任务的规则。
- 经验性描述太长：压缩成“什么时候触发 + 必须怎么做”。
- Claude Code 专属规则：留在 `MEMORY.md` 或 Claude Code 区域，不要写入 Codex 全局 `AGENTS.md`。
- Codex 专属规则：放到 `codex/AGENTS.md`，不要强迫 Claude Code 读取。
- 项目规则和全局规则冲突：以项目内更具体的 `AGENTS.md` 为准，全局文件只保留通用默认值。

解决冲突后：

```bash
git add MEMORY.md codex/AGENTS.md
git rebase --continue
git push
```

### 推荐目录约定

```text
my-memory/
├── README.md
├── MEMORY.md                  # Claude Code 与通用共享记忆
├── feishu-doc-workflow.md
└── codex/
    └── AGENTS.md              # Codex 全局稳定指令，建议 symlink 到 ~/.codex/AGENTS.md
```

当前仓库可能尚未创建 `codex/AGENTS.md`。第一次接入 Codex 时，用上面的命令从 `MEMORY.md` 复制一份，再人工删掉 Claude Code 专属内容即可。

## 新机器初始化（一键）

```bash
# 1. 克隆本仓库（GitHub 和 Gitee 共用同一 SSH key）
git clone git@github.com:yinrong/my-memory.git ~/my-memory

# 2. 确保 Claude Code 项目记忆目录存在（home 目录对应的项目路径）
mkdir -p ~/.claude/projects/-home-ubuntu

# 3. 若 memory 目录已存在则移除（空目录或旧 symlink）
rm -rf ~/.claude/projects/-home-ubuntu/memory

# 4. 创建 symlink：Claude Code 的记忆直接读写本仓库
ln -s ~/my-memory ~/.claude/projects/-home-ubuntu/memory

# 5. 验证
ls ~/.claude/projects/-home-ubuntu/memory/MEMORY.md
```

执行完毕后，Claude Code 在 `~/` 下任何项目的对话中都会自动加载 `MEMORY.md` 作为全局记忆。

### 原理

Claude Code 的 auto memory 功能会读写 `~/.claude/projects/<escaped-cwd>/memory/` 目录。通过 symlink 到本 git 仓库，记忆文件的变更可以用标准 git 工作流推送/拉取，实现多机同步。

### 同步记忆到远端

```bash
cd ~/my-memory && git add -A && git commit -m "sync: update memory" && git push
```

### 每周平均一次自动 push

如果希望 cron 每天检查一次，但 7 天内已经成功执行过就跳过，使用仓库内的脚本：

```bash
chmod +x ~/my-memory/weekly-push-if-due.sh

# 每天 03:00 检查一次；脚本内部保证 7 天内成功执行过就跳过
(crontab -l 2>/dev/null; echo "0 3 * * * cd ~/my-memory && ./weekly-push-if-due.sh >> ~/my-memory/weekly-push.log 2>&1") | crontab -
```

脚本会把上次成功执行时间记录在：

```text
~/.local/state/my-memory/last-successful-push
```

需要调整周期时，可以设置环境变量，例如每 14 天一次：

```cron
0 3 * * * cd ~/my-memory && MY_MEMORY_INTERVAL_DAYS=14 ./weekly-push-if-due.sh >> ~/my-memory/weekly-push.log 2>&1
```

---

## 自动化同步方案（脚本存在时）

下面是本仓库规划/历史约定的自动化同步方案。当前分支如果没有 `setup.sh`、`sync-memory.sh`、`pull-and-merge.sh`、`decrypt-memory.sh`，请以上面的手动 Git 流程为准；只有在脚本实际存在后，才执行本节命令。

### 功能特性

- ✅ **自动定时同步**：每天自动推送本机记忆到 GitHub
- ✅ **加密存储**：使用密码加密，GitHub 上无法直接读取
- ✅ **多主机支持**：每台机器独立分支，互不覆盖
- ✅ **智能融合**：自动融合多个主机的记忆到 `common` 分支
- ✅ **本地解密**：使用本地密码解密查看

## 目录结构

```
my-memory/
├── README.md                 # 本文件
├── setup.sh                  # 可选：一键安装脚本
├── sync-memory.sh            # 可选：同步脚本（加密、推送）
├── pull-and-merge.sh         # 可选：拉取并融合脚本
├── decrypt-memory.sh         # 可选：解密查看脚本
├── .gitignore
└── hosts/
    ├── <hostname>/           # 每台主机一个目录
    │   ├── CLAUDE.md.enc     # 加密的全局 CLAUDE.md
    │   ├── MEMORY.md.enc     # 加密的 MEMORY.md
    │   ├── *.md.enc          # 其他加密的记忆文件
    │   └── metadata.json     # 主机信息和时间戳
    └── common/               # 融合后的公共记忆
        ├── CLAUDE.md
        ├── MEMORY.md
        └── *.md
```

## 快速开始

### 1. 在第一台主机上安装

```bash
# 克隆项目（如果已存在）或创建新项目
cd ~/my-memory

# 运行一键安装
bash setup.sh

# 按提示输入：
# - 你的加密密码（用于加密记忆文件）
# - GitHub 仓库 URL（如 git@github.com:yinrong/my-memory.git）
```

### 2. 在其他主机上安装

```bash
# 克隆项目
git clone git@github.com:yinrong/my-memory.git
cd my-memory

# 运行安装（会自动拉取并融合其他主机的记忆）
bash setup.sh
```

### 3. 自动运行

安装后，系统会：
- ✅ 每天 03:00 自动同步本机记忆到 GitHub
- ✅ 每天 03:30 自动拉取并融合其他主机的记忆
- ✅ 融合后的记忆自动应用到本机 Claude Code

## 手动操作

### 立即同步

```bash
cd ~/my-memory
./sync-memory.sh
```

### 立即拉取并融合

```bash
cd ~/my-memory
./pull-and-merge.sh
```

### 查看加密的记忆（解密）

```bash
cd ~/my-memory
./decrypt-memory.sh hosts/<hostname>/CLAUDE.md.enc
```

### 查看融合后的公共记忆

```bash
cat ~/my-memory/hosts/common/MEMORY.md
```

## 工作原理

### 同步流程（每天 03:00）

1. 读取 `~/.claude/CLAUDE.md` 和 `~/.claude/global-memory/`
2. 使用密码加密（AES-256）
3. 保存到 `hosts/<hostname>/` 目录
4. Commit 并推送到 GitHub（分支：`host/<hostname>`）

### 融合流程（每天 03:30）

1. 从 GitHub 拉取所有主机分支
2. 解密每个主机的记忆文件
3. 智能融合：
   - 合并相同主题的内容
   - 保留各主机独特的经验
   - 去重和冲突解决
4. 生成 `hosts/common/` 目录
5. 推送到 `common` 分支
6. 将 `common` 内容应用到本机 `~/.claude/`

### 加密方式

使用 OpenSSL AES-256-CBC 加密：

```bash
# 加密
openssl enc -aes-256-cbc -salt -pbkdf2 -in file.md -out file.md.enc -k 'your-password'

# 解密
openssl enc -aes-256-cbc -d -pbkdf2 -in file.md.enc -out file.md -k 'your-password'
```

密码存储在 `~/.my-memory-password`（不提交到 Git）

## 安全性

- ✅ 密码仅存储在本地 `~/.my-memory-password`
- ✅ GitHub 上只有加密文件，无法直接读取
- ✅ 解密需要本地密码文件
- ✅ `.my-memory-password` 加入 `.gitignore`

## 定时任务

安装后可创建 cron 任务：

```cron
# 每天 03:00 检查一次；7 天内成功执行过则跳过
0 3 * * * cd ~/my-memory && ./weekly-push-if-due.sh >> ~/my-memory/weekly-push.log 2>&1

# 每天 03:30 拉取并融合
30 3 * * * cd ~/my-memory && ./pull-and-merge.sh >> ~/my-memory/merge.log 2>&1
```

查看定时任务：
```bash
crontab -l | grep my-memory
```

查看日志：
```bash
tail -f ~/my-memory/weekly-push.log
tail -f ~/my-memory/merge.log
```

## 多主机示例

假设你有 3 台机器：

```
GitHub 仓库结构：
├── main 分支（本 README）
├── host/laptop 分支
│   └── hosts/laptop/
│       ├── CLAUDE.md.enc
│       └── MEMORY.md.enc
├── host/desktop 分支
│   └── hosts/desktop/
│       ├── CLAUDE.md.enc
│       └── MEMORY.md.enc
├── host/server 分支
│   └── hosts/server/
│       ├── CLAUDE.md.enc
│       └── MEMORY.md.enc
└── common 分支（融合后）
    └── hosts/common/
        ├── CLAUDE.md
        └── MEMORY.md
```

每台机器：
1. 维护自己的分支（`host/<hostname>`）
2. 定时推送加密的记忆
3. 定时拉取并融合所有主机的记忆
4. 应用融合后的公共记忆

## 故障排查

### 密码丢失

密码存储在 `~/.my-memory-password`。如果丢失：
1. 在另一台有密码的机器上查看 `cat ~/.my-memory-password`
2. 或者删除 GitHub 仓库，重新开始

### 同步失败

检查日志：
```bash
tail -20 ~/my-memory/sync.log
```

常见问题：
- Git 权限问题：检查 SSH 密钥
- 密码文件不存在：运行 `./setup.sh` 重新设置
- 网络问题：稍后自动重试

### 融合冲突

如果自动融合失败，手动解决：
```bash
cd ~/my-memory
git fetch --all
git checkout common
# 手动编辑 hosts/common/ 下的文件
git add .
git commit -m "Manual merge"
git push origin common
```

## 卸载

```bash
# 停止定时任务
crontab -l | grep -v my-memory | crontab -

# 删除项目（可选）
rm -rf ~/my-memory

# GitHub 仓库保留（作为备份）
```

## 进阶配置

### 修改同步时间

编辑 crontab：
```bash
crontab -e

# 改成每 6 小时同步
0 */6 * * * cd ~/my-memory && ./sync-memory.sh >> ~/my-memory/sync.log 2>&1
```

### 排除某些文件

编辑 `sync-memory.sh`，在 `FILES_TO_SYNC` 变量中移除不需要的文件。

### 自定义融合规则

编辑 `pull-and-merge.sh` 中的 `merge_memories()` 函数。

## 许可证

MIT License

## 作者

Created for managing Claude Code global memory across multiple hosts.
