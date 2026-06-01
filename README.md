# My Memory - 跨主机全局记忆同步系统

自动同步和融合多台机器上的 Claude Code 全局记忆，支持加密存储。

## 功能特性

- ✅ **自动定时同步**：每天自动推送本机记忆到 GitHub
- ✅ **加密存储**：使用密码加密，GitHub 上无法直接读取
- ✅ **多主机支持**：每台机器独立分支，互不覆盖
- ✅ **智能融合**：自动融合多个主机的记忆到 `common` 分支
- ✅ **本地解密**：使用本地密码解密查看

## 目录结构

```
my-memory/
├── README.md                 # 本文件
├── setup.sh                  # 一键安装脚本
├── sync-memory.sh            # 同步脚本（加密、推送）
├── pull-and-merge.sh         # 拉取并融合脚本
├── decrypt-memory.sh         # 解密查看脚本
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

安装后会创建 cron 任务：

```cron
# 每天 03:00 同步记忆到 GitHub
0 3 * * * cd ~/my-memory && ./sync-memory.sh >> ~/my-memory/sync.log 2>&1

# 每天 03:30 拉取并融合
30 3 * * * cd ~/my-memory && ./pull-and-merge.sh >> ~/my-memory/merge.log 2>&1
```

查看定时任务：
```bash
crontab -l | grep my-memory
```

查看日志：
```bash
tail -f ~/my-memory/sync.log
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
