# dev-env-setup — 跨平台基础开发环境包

一套脚本，在 **Linux / macOS / Windows** 上装齐基础开发工具链并部署统一配置。
配套 [proxy.sh](proxy.sh) 提供跨环境代理自动探测与切换（WSL2 全网络模式 / WSL1 / 原生 Linux / macOS）。

> ⚠️ **本仓库不含任何密钥**（GitHub token、API key 均不收录）。认证在装完后交互完成：
> `gh auth login` + `opencode auth login`。凭证迁移请使用私有仓库（如 wsl-migration）。

---

## 安装内容

| 类别 | 工具 | 安装方式 |
|---|---|---|
| 基础包 | git / curl / tmux / vim / jq / htop / tree / rsync / ripgrep / unzip / zip + 编译工具链 | apt / dnf / pacman / brew 自动识别 |
| Python | python3 + **uv** | 系统自带 + 官方脚本 |
| Node.js | 22 LTS | nodesource（apt/dnf）/ pacman / brew / winget |
| npm 全局 | 镜像源 + **pnpm / bun / opencode-ai** | npm |
| GitHub CLI | **gh** | 官方二进制 / 包管理器 / winget |
| 配置 | gitconfig / npmrc / git-ignore / gh / opencode 全套（含 6 个内置技能） | 自动部署，旧配置备份到 `~/.dev-env-setup-backup` |

## 快速开始

### Linux / macOS

```bash
git clone https://github.com/Lcxzero/dev-env-setup.git
cd dev-env-setup
bash setup.sh
```

支持发行版：Debian/Ubuntu（apt）、Fedora/RHEL（dnf）、Arch（pacman）、macOS（Homebrew，缺失时自动安装）。

### Windows

```powershell
git clone https://github.com/Lcxzero/dev-env-setup.git
cd dev-env-setup
Set-ExecutionPolicy -Scope Process Bypass
.\setup-windows.ps1
```

依赖 winget（Windows 10 1809+ / Windows 11 自带）。安装工具：Git / gh / Node 22 / ripgrep / jq / uv。

## 代理（proxy.sh）

```bash
bash proxy.sh start    # 自动探测: 现有代理 → resolv.conf → 默认网关 → 127.0.0.1
                       #            × 常见端口 10808/7890/7897/1080/8118
bash proxy.sh stop     # 全部清除
bash proxy.sh status   # 当前状态 + 可用代理
```

- 配置目标：shell rc（bash/zsh）、git 全局、apt（Debian 系）、dnf（Fedora 系）、systemd-user environment.d，逐项汇报 ✓/✗
- 手动指定：`PROXY_HOST=1.2.3.4 PROXY_PORT=7890 bash proxy.sh start`
- Windows 本机不走此脚本（系统代理软件全局接管）

## 环境变量开关（setup.sh）

| 变量 | 作用 |
|---|---|
| `SKIP_INSTALL=1` | 只部署配置，不装软件 |
| `NO_PROXY=1` | 跳过代理配置 |
| `PROXY_PORT=7890` | 指定代理端口 |
| `NO_AI=1` / `NO_GH=1` | 跳过 opencode / gh |
| `NPM_REGISTRY=none` | 不设 npm 国内镜像 |

（setup-windows.ps1 对应 `-SkipInstall` / `-NoAI` 参数）

## 已适配 / 未覆盖

| 场景 | 状态 |
|---|---|
| WSL2 NAT + DNS 隧道（resolv.conf 不指向宿主） | ✅ 网关探测兜底 |
| WSL2 mirrored / WSL1 / 原生 Linux | ✅ |
| macOS（Intel/Apple Silicon） | ✅ bash 3.2 兼容 |
| Debian / Fedora / Arch / macOS 包管理器差异 | ✅ 自动识别 |
| 无 root/sudo 免密 | ⚠️ apt/dnf 步骤会标 ✗，其余不受影响 |
| 代理软件未运行 | ✅ 明确报错（列出已尝试的宿主和端口），不会绑死死 IP |

实测环境：WSL2 Ubuntu（NAT+DNS 隧道）。其他平台按检测逻辑适配，欢迎提 issue 反馈。

## 目录结构

```
dev-env-setup/
├── setup.sh             # Linux / macOS 一站式安装
├── setup-windows.ps1    # Windows 一站式安装
├── proxy.sh             # 跨平台代理切换
└── config/
    ├── gitconfig        # 身份 + gh 凭证助手（代理由 proxy.sh 动态管理）
    ├── npmrc            # npmmirror + ${HOME} 全局目录
    ├── git-ignore
    ├── gh/config.yml    # gh 通用配置（不含 token）
    └── opencode/        # opencode 全套配置 + 内置技能（不含密钥）
```

## FAQ

**Q: 密钥怎么迁？**
本包不携带任何凭证。装完后：`gh auth login`（GitHub）、`opencode auth login`（AI 密钥）。已有机器间迁移凭证用私有仓库。

**Q: 用户名/邮箱是我自己的怎么办？**
改 `config/gitconfig` 的 `[user]` 段，或装完后 `git config --global user.name "你"`。

**Q: opencode 技能路径？**
`opencode.jsonc` 的 `skills.paths` 会被 setup 脚本自动改写为实际的 `~/repos/skill/skills`（技能源：github.com/anbeime/skill）。
