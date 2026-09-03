#!/usr/bin/env bash
# ============================================================
# dev-env-setup — 基础开发环境一站式安装（Linux / macOS）
#   bash setup.sh
# 环境变量开关:
#   SKIP_INSTALL=1   只部署配置，不装任何软件
#   NO_PROXY=1       跳过代理配置
#   PROXY_PORT=7890  指定代理端口（默认自动探测常见端口）
#   NO_AI=1          跳过 opencode-ai
#   NO_GH=1          跳过 GitHub CLI
#   NPM_REGISTRY=none 跳过 npm 国内镜像
# ============================================================
set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
OKS=(); FAILS=()
ok()   { OKS+=("$1");   echo -e "${GREEN}[✓]${NC} $1"; }
fail() { FAILS+=("$1"); echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

SKIP_INSTALL="${SKIP_INSTALL:-0}"; NO_PROXY="${NO_PROXY:-0}"; NO_AI="${NO_AI:-0}"
NO_GH="${NO_GH:-0}"; NPM_REGISTRY="${NPM_REGISTRY:-}"

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dev-env-setup-backup"
[ -f "$PKG_DIR/proxy.sh" ] || { echo "请在仓库根目录运行: bash setup.sh"; exit 1; }

SUDO=""
[ "$(id -u)" != "0" ] && SUDO="sudo"

# ---------- 环境识别 ----------
OS="$(uname -s)"
ARCH="$(uname -m)"
PKG=""
if [ "$OS" = "Darwin" ]; then PKG="brew"
elif command -v apt-get >/dev/null 2>&1; then PKG="apt"
elif command -v dnf >/dev/null 2>&1; then PKG="dnf"
elif command -v pacman >/dev/null 2>&1; then PKG="pacman"
fi
echo "环境: OS=$OS ARCH=$ARCH 包管理器=${PKG:-未识别}"

pkg_install() {  # pkg_install <包名...>
    case "$PKG" in
        apt)    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@" ;;
        dnf)    $SUDO dnf install -y "$@" ;;
        pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
        brew)   brew install "$@" ;;
        *)      return 1 ;;
    esac
}

# ---------- Phase 1: 代理 ----------
echo ""; echo "== Phase 1/7 代理 =="
mkdir -p "$HOME/.local/bin"
cp "$PKG_DIR/proxy.sh" "$HOME/.local/bin/proxy" && chmod +x "$HOME/.local/bin/proxy" && ok "proxy.sh → ~/.local/bin/proxy"
if [ "$NO_PROXY" = "1" ]; then
    warn "NO_PROXY=1，跳过代理启动"
elif bash "$HOME/.local/bin/proxy" start; then
    ok "代理已启动并写入 shell rc / git / 包管理器"
else
    warn "代理未启动（不影响安装，稍后可 bash ~/.local/bin/proxy start）"
fi

# ---------- Phase 2: 基础工具 ----------
if [ "$SKIP_INSTALL" = "1" ]; then
    echo ""; warn "SKIP_INSTALL=1，跳过全部软件安装"
else
    echo ""; echo "== Phase 2/7 基础工具 =="
    case "$PKG" in
        apt)    $SUDO apt-get update -y >/dev/null 2>&1; pkg_install git curl tmux vim jq htop tree rsync ripgrep net-tools dnsutils lsof unzip zip build-essential ca-certificates >/dev/null 2>&1 && ok "apt 基础工具" || fail "apt 基础工具" ;;
        dnf)    pkg_install git curl tmux vim jq htop tree rsync ripgrep lsof unzip zip gcc gcc-c++ make >/dev/null 2>&1 && ok "dnf 基础工具" || fail "dnf 基础工具" ;;
        pacman) pkg_install git curl tmux vim jq htop tree rsync ripgrep lsof unzip zip base-devel >/dev/null 2>&1 && ok "pacman 基础工具" || fail "pacman 基础工具" ;;
        brew)   command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; pkg_install git curl tmux vim jq htop tree rsync ripgrep >/dev/null 2>&1 && ok "brew 基础工具" || fail "brew 基础工具" ;;
        *)      fail "未识别的包管理器，请手动安装 git/curl/tmux/jq 等" ;;
    esac
fi

# ---------- Phase 3: Node.js 22 ----------
if [ "$SKIP_INSTALL" = "1" ]; then
    :
else
    echo ""; echo "== Phase 3/7 Node.js =="
    NODE_MAJOR=0
    command -v node >/dev/null 2>&1 && NODE_MAJOR="$(node -v | sed 's/^v//' | cut -d. -f1)"
    if [ "$NODE_MAJOR" -ge 20 ] 2>/dev/null; then
        ok "Node.js $(node -v) 已存在，跳过"
    else
        case "$PKG" in
            apt)    curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource.sh 2>/dev/null && $SUDO bash /tmp/nodesource.sh >/dev/null 2>&1 && rm -f /tmp/nodesource.sh && $SUDO apt-get install -y nodejs >/dev/null 2>&1 ;;
            dnf)    curl -fsSL https://rpm.nodesource.com/setup_22.x -o /tmp/nodesource.sh 2>/dev/null && $SUDO bash /tmp/nodesource.sh >/dev/null 2>&1 && rm -f /tmp/nodesource.sh && $SUDO dnf install -y nodejs >/dev/null 2>&1 ;;
            pacman) pkg_install nodejs npm >/dev/null 2>&1 ;;
            brew)   pkg_install node@22 >/dev/null 2>&1 && brew link --overwrite node@22 >/dev/null 2>&1 ;;
        esac
        command -v node >/dev/null 2>&1 && ok "Node.js $(node -v)" || fail "Node.js 22"
    fi
    command -v npm >/dev/null 2>&1 && ok "npm $(npm -v)" || fail "npm"
fi

# ---------- Phase 4: uv ----------
if [ "$SKIP_INSTALL" = "1" ]; then
    :
else
    echo ""; echo "== Phase 4/7 Python/uv =="
    if command -v uv >/dev/null 2>&1; then
        ok "uv $(uv --version | awk '{print $2}') 已存在"
    elif curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
        export PATH="$HOME/.local/bin:$PATH"
        ok "uv 安装完成"
    else
        fail "uv 安装"
    fi
fi

# ---------- Phase 5: GitHub CLI ----------
if [ "$SKIP_INSTALL" = "1" ] || [ "$NO_GH" = "1" ]; then
    echo ""; warn "跳过 GitHub CLI"
else
    echo ""; echo "== Phase 5/7 GitHub CLI =="
    if command -v gh >/dev/null 2>&1; then
        ok "gh $(gh --version | awk '{print $3}' | head -1) 已存在"
    elif [ "$PKG" = "pacman" ]; then
        pkg_install github-cli >/dev/null 2>&1 && ok "gh (pacman)" || fail "gh"
    elif [ "$PKG" = "brew" ]; then
        pkg_install gh >/dev/null 2>&1 && ok "gh (brew)" || fail "gh"
    else
        GH_VER="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep -oE '"tag_name": *"v[^"]+"' | cut -d'"' -f4 | sed 's/^v//')"
        GH_OS="$(echo "$OS" | tr 'A-Z' 'a-z')"
        GH_ARCH="$(echo "$ARCH" | sed 's/^x86_64$/amd64/; s/^aarch64$/arm64/; s/^arm64$/arm64/')"
        if [ -n "$GH_VER" ] && [ -n "$GH_ARCH" ] \
           && curl -fsSL -o /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VER}/gh_${GH_VER}_${GH_OS}_${GH_ARCH}.tar.gz" 2>/dev/null \
           && $SUDO tar -C /usr/local --strip-components=1 -xzf /tmp/gh.tar.gz "gh_${GH_VER}_${GH_OS}_${GH_ARCH}/bin/gh" 2>/dev/null \
           && rm -f /tmp/gh.tar.gz; then
            ok "gh ${GH_VER}（官方二进制）"
        else
            fail "gh（手动: https://github.com/cli/cli/releases）"
        fi
    fi
fi

# ---------- Phase 6: npm 全局 ----------
if [ "$SKIP_INSTALL" = "1" ]; then
    :
else
    echo ""; echo "== Phase 6/7 npm 全局 =="
    if command -v npm >/dev/null 2>&1; then
        if [ "$NPM_REGISTRY" != "none" ]; then
            npm config set registry https://registry.npmmirror.com && ok "npm 镜像 npmmirror"
        fi
        npm install -g pnpm bun >/dev/null 2>&1 && ok "pnpm / bun" || fail "pnpm / bun"
        if [ "$NO_AI" != "1" ]; then
            npm install -g opencode-ai >/dev/null 2>&1 && ok "opencode-ai" || fail "opencode-ai"
        fi
    else
        fail "npm 不可用，跳过全局工具"
    fi
fi

# ---------- Phase 7: 配置部署 ----------
echo ""; echo "== Phase 7/7 配置部署 =="
mkdir -p "$BACKUP"
backup() { [ -e "$1" ] && cp -a "$1" "$BACKUP/$(basename "$1").bak" 2>/dev/null; return 0; }

backup "$HOME/.gitconfig"; cp "$PKG_DIR/config/gitconfig" "$HOME/.gitconfig" && ok "gitconfig"
backup "$HOME/.npmrc";     cp "$PKG_DIR/config/npmrc"     "$HOME/.npmrc"     && ok "npmrc"
mkdir -p "$HOME/.config/git"; backup "$HOME/.config/git/ignore"
cp "$PKG_DIR/config/git-ignore" "$HOME/.config/git/ignore" && ok "git ignore"

mkdir -p "$HOME/.config/gh"; backup "$HOME/.config/gh/config.yml"
cp "$PKG_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml" && chmod 600 "$HOME/.config/gh/config.yml" && ok "gh config（认证请运行: gh auth login）"

mkdir -p "$HOME/.config/opencode"
for f in opencode.json opencode.jsonc oh-my-openagent.json tui.json package.json package-lock.json; do
    backup "$HOME/.config/opencode/$f"; cp "$PKG_DIR/config/opencode/$f" "$HOME/.config/opencode/$f"
done
ok "opencode 配置（密钥请运行: opencode auth login）"
if [ ! -d "$HOME/.config/opencode/skills" ]; then
    cp -a "$PKG_DIR/config/opencode/skills" "$HOME/.config/opencode/skills" && ok "opencode 内置技能 ×6"
fi
if command -v npm >/dev/null 2>&1 && [ ! -d "$HOME/.config/opencode/node_modules" ]; then
    (cd "$HOME/.config/opencode" && npm install --no-audit --no-fund >/dev/null 2>&1) && ok "opencode 插件依赖" || warn "opencode npm install 失败（首次启动会自动重试）"
fi

# 技能仓库（代理优先，zip 兜底）
SKILL_DIR="$HOME/repos/skill"
if [ -d "$SKILL_DIR" ]; then
    ok "技能仓库已存在: $SKILL_DIR"
else
    mkdir -p "$HOME/repos"
    if git clone --depth 1 https://github.com/anbeime/skill.git "$SKILL_DIR" 2>/dev/null \
       || curl -fsSL --retry 2 --max-time 120 https://codeload.github.com/anbeime/skill/zip/refs/heads/main -o /tmp/skill.zip 2>/dev/null \
          && unzip -qo /tmp/skill.zip -d /tmp/skill-zip 2>/dev/null \
          && mv /tmp/skill-zip/skill-main "$SKILL_DIR" 2>/dev/null; then
        rm -rf /tmp/skill.zip /tmp/skill-zip
        N_SKILL="$(ls "$SKILL_DIR/skills" 2>/dev/null | wc -l)"
        ok "技能仓库 ×${N_SKILL}"
    else
        rm -rf /tmp/skill.zip /tmp/skill-zip "$SKILL_DIR"
        warn "技能仓库获取失败（可手动: git clone https://github.com/anbeime/skill.git ~/repos/skill）"
    fi
fi
# 把 opencode.jsonc 的技能路径改为实际克隆位置
if [ -f "$HOME/.config/opencode/opencode.jsonc" ]; then
    sed -i "s|\"paths\": \[\"[^\"]*\"\]|\"paths\": [\"$HOME/repos/skill/skills\"]|" "$HOME/.config/opencode/opencode.jsonc"
fi

# PATH + proxy() 包装写入 rc
RC_MARK="# >>> dev-env-setup >>>"
RC_BLOCK="${RC_MARK}
export PATH=\"\$HOME/.local/bin:\$HOME/.npm-global/bin:\$PATH\"
proxy() { source \"\$HOME/.local/bin/proxy\" \"\$@\"; }
# <<< dev-env-setup <<<"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] || [ "$rc" = "$HOME/.bashrc" ]; then
        grep -qF "$RC_MARK" "$rc" 2>/dev/null || { printf '\n%s\n' "$RC_BLOCK" >> "$rc"; ok "$(basename "$rc") 已追加 PATH/proxy"; }
    fi
done

# ---------- 汇总 ----------
echo ""; echo "=============================================="
echo " 安装汇总: ${#OKS[@]} 成功 / ${#FAILS[@]} 失败"
[ ${#FAILS[@]} -gt 0 ] && printf '  ✗ %s\n' "${FAILS[@]}"
echo "=============================================="
echo " 下一步:"
echo "   source ~/.bashrc          # 生效"
echo "   gh auth login             # GitHub 认证"
echo "   opencode auth login       # AI provider 密钥（本包不含密钥）"
echo "   proxy status              # 代理状态"
echo " 旧配置备份: $BACKUP"
