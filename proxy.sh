#!/usr/bin/env bash
# ============================================================
# proxy.sh — 跨平台通用代理切换
# 适配: WSL2(NAT / DNS隧道 / mirrored) / WSL1 / 原生 Linux / macOS / 本机代理
# 用法: proxy.sh start|stop|status
# 覆盖: PROXY_HOST=1.2.3.4 PROXY_PORT=7890 bash proxy.sh start
#
# start 会配置以下目标（存在才配，逐项汇报 ✓/✗）:
#   shell rc (~/.bashrc + ~/.zshrc) / git 全局 / apt / dnf /
#   systemd-user environment.d (Linux)
# ============================================================
set -u

PORTS="${PROXY_PORT:-10808 7890 7897 1080 8118}"   # 未指定端口则逐个探测常见代理端口
PROXY_PORT="${PROXY_PORT:-}"
APT_FILE="/etc/apt/apt.conf.d/01proxy"
DNF_FILE="/etc/dnf/dnf.conf"
ENV_D_FILE="$HOME/.config/environment.d/90-proxy.conf"
MARK_B="# >>> proxy-universal config >>>"
MARK_E="# <<< proxy-universal config <<<"
MARK_LB="# >>> WSL2 proxy config >>>"   # 兼容清理旧版 wsl-migration proxy 脚本的块
MARK_LE="# <<< WSL2 proxy config <<<"

# ---------- 环境识别 ----------
OS="$(uname -s)"
ENV_NAME="linux"
if grep -qi microsoft /proc/version 2>/dev/null; then
    ENV_NAME="wsl2"
    case "$(uname -r)" in
        *microsoft-standard*|*WSL2*) : ;;
        *) ENV_NAME="wsl1" ;;
    esac
    if command -v wslinfo >/dev/null 2>&1; then
        nm="$(wslinfo --networking-mode 2>/dev/null)"
        [ -n "$nm" ] && ENV_NAME="wsl2-${nm}"
    fi
elif [ "$OS" = "Darwin" ]; then
    ENV_NAME="macos"
fi

default_gateway() {
    if [ "$OS" = "Darwin" ]; then
        route -n get default 2>/dev/null | awk '/gateway/{print $2}' | head -1
    else
        ip route show default 2>/dev/null | awk '{print $3}' | head -1
    fi
}

# 候选宿主 IP（按优先级去重）: 现有代理环境变量 → resolv.conf nameserver → 默认网关 → 127.0.0.1
candidate_hosts() {
    if [ -n "${HTTPS_PROXY:-}" ] && [[ "$HTTPS_PROXY" =~ ^http://([^:/]+): ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [ -n "${HTTP_PROXY:-}" ] && [[ "$HTTP_PROXY" =~ ^http://([^:/]+): ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
    grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}'
    default_gateway
    echo "127.0.0.1"
}

probe() {  # probe <host> <port> — TCP 连通测试
    local h="$1" p="$2"
    if command -v timeout >/dev/null 2>&1; then
        timeout 2 bash -c "echo > /dev/tcp/${h}/${p}" 2>/dev/null && return 0
    elif command -v nc >/dev/null 2>&1; then
        nc -z -G 2 "$h" "$p" >/dev/null 2>&1 && return 0
    else
        (exec 3<>"/dev/tcp/${h}/${p}") 2>/dev/null && return 0
    fi
    return 1
}

# 探测可达的 host:port（首个可用者胜出）
pick_endpoint() {
    local hosts h p
    if [ -n "${PROXY_HOST:-}" ]; then
        hosts="${PROXY_HOST}"
    else
        hosts="$(candidate_hosts | awk '!seen[$0]++')"
    fi
    for h in $hosts; do
        for p in $PORTS; do
            if probe "$h" "$p"; then
                echo "${h}:${p}"
                return 0
            fi
        done
    done
    return 1
}

# ---------- shell rc 管理 ----------
rc_files() {
    local shell_name; shell_name="$(basename "${SHELL:-/bin/bash}")"
    if [ "$shell_name" = "zsh" ]; then
        echo "$HOME/.zshrc"
        [ -f "$HOME/.bashrc" ] && echo "$HOME/.bashrc"
    else
        echo "$HOME/.bashrc"
        [ -f "$HOME/.zshrc" ] && echo "$HOME/.zshrc"
    fi
}

rc_block() {
    cat <<PROXYEOF
${MARK_B}
export HTTP_PROXY="${PROXY_URL}"
export HTTPS_PROXY="${PROXY_URL}"
export http_proxy="${PROXY_URL}"
export https_proxy="${PROXY_URL}"
export NO_PROXY="localhost,127.0.0.1,::1,*.local"
export no_proxy="\${NO_PROXY}"
${MARK_E}
PROXYEOF
}

# 删除一个 rc 文件中的自有块与旧版块，输出到 stdout
rc_clean() {
    local f="$1"
    sed "/${MARK_B}/,/${MARK_E}/d; /${MARK_LB}/,/${MARK_LE}/d" "$f" 2>/dev/null
}

write_rc() {  # write_rc <rc文件>
    local f="$1" tmp
    [ -f "$f" ] || : > "$f"
    tmp="$(mktemp)"
    rc_clean "$f" > "$tmp"
    rc_block >> "$tmp"
    cat "$tmp" > "$f" && rm -f "$tmp"
}

clean_rc() {  # clean_rc <rc文件>
    local f="$1" tmp
    grep -qF "$MARK_B" "$f" 2>/dev/null || grep -qF "$MARK_LB" "$f" 2>/dev/null || return 0
    [ -f "$f" ] || return 0
    tmp="$(mktemp)"
    rc_clean "$f" > "$tmp"
    cat "$tmp" > "$f" && rm -f "$tmp"
}

# ---------- 子命令 ----------
case "${1:-status}" in
    start|on)
        # 0. 探测 endpoint
        HOST_PORT="$(pick_endpoint || true)"
        if [ -z "$HOST_PORT" ]; then
            echo "[✗] 未探测到可用代理"
            echo "    已尝试宿主: $(candidate_hosts | awk '!seen[$0]++' | tr '\n' ' ')"
            echo "    已尝试端口: $PORTS"
            echo "    手动指定: PROXY_HOST=<IP> PROXY_PORT=<端口> bash $0 start"
            exit 1
        fi
        PROXY_HOST="${HOST_PORT%%:*}"
        PROXY_PORT="${HOST_PORT##*:}"
        PROXY_URL="http://${HOST_PORT}"
        echo "[✓] 探测到代理: ${PROXY_URL}（环境: ${ENV_NAME}）"

        # 1. 当前 shell 立即生效
        export HTTP_PROXY="$PROXY_URL" HTTPS_PROXY="$PROXY_URL"
        export http_proxy="$PROXY_URL" https_proxy="$PROXY_URL"
        export NO_PROXY="localhost,127.0.0.1,::1,*.local" no_proxy="localhost,127.0.0.1,::1,*.local"

        # 2. shell rc（bash + zsh 全管理）
        RC_SUM=""; RC_OK=0; RC_N=0
        for f in $(rc_files); do
            write_rc "$f"; RC_N=$((RC_N+1)); RC_OK=$((RC_OK+1))
            RC_SUM="${RC_SUM:+$RC_SUM }$(basename "$f")"
        done

        # 3. git 全局
        GIT_MARK="n/a"
        if command -v git >/dev/null 2>&1; then
            git config --global http.proxy "$PROXY_URL" 2>/dev/null
            git config --global https.proxy "$PROXY_URL" 2>/dev/null
            [ "$(git config --global http.proxy 2>/dev/null)" = "$PROXY_URL" ] && GIT_MARK="✓" || GIT_MARK="✗"
        fi

        # 4. apt（Debian/Ubuntu）
        APT_MARK="n/a"
        if command -v apt-get >/dev/null 2>&1; then
            CONF="Acquire::http::proxy \"${PROXY_URL}\";
Acquire::https::proxy \"${PROXY_URL}\";
Acquire::ftp::proxy \"${PROXY_URL}\";"
            if echo "$CONF" | sudo -n tee "$APT_FILE" >/dev/null 2>&1 || echo "$CONF" | sudo tee "$APT_FILE" >/dev/null 2>&1; then
                APT_MARK="✓"
            else
                APT_MARK="✗（需要 sudo）"
            fi
        fi

        # 5. dnf（Fedora/RHEL）
        DNF_MARK="n/a"
        if command -v dnf >/dev/null 2>&1 && [ -f "$DNF_FILE" ]; then
            if sudo -n sh -c "sed -i '/^proxy=/d' '$DNF_FILE'; printf 'proxy=%s\n' '$PROXY_URL' >> '$DNF_FILE'" 2>/dev/null \
               || sudo sh -c "sed -i '/^proxy=/d' '$DNF_FILE'; printf 'proxy=%s\n' '$PROXY_URL' >> '$DNF_FILE'" 2>/dev/null; then
                DNF_MARK="✓"
            else
                DNF_MARK="✗（需要 sudo）"
            fi
        fi

        # 6. systemd-user environment.d（Linux 图形/systemd 服务）
        ENVD_MARK="n/a"
        if [ "$OS" = "Linux" ] && systemctl --user status >/dev/null 2>&1; then
            mkdir -p "$(dirname "$ENV_D_FILE")"
            { echo "HTTP_PROXY=${PROXY_URL}"; echo "HTTPS_PROXY=${PROXY_URL}";
              echo "http_proxy=${PROXY_URL}"; echo "https_proxy=${PROXY_URL}";
              echo 'NO_PROXY=localhost,127.0.0.1,::1,*.local'; echo 'no_proxy=localhost,127.0.0.1,::1,*.local'; } > "$ENV_D_FILE" \
              && ENVD_MARK="✓" || ENVD_MARK="✗"
        fi

        echo "  已配置代理: shell rc(${RC_SUM}) ✓ | git ${GIT_MARK} | apt ${APT_MARK} | dnf ${DNF_MARK} | env.d ${ENVD_MARK}"

        CODE=$(curl -s --connect-timeout 3 -o /dev/null -w "%{http_code}" https://github.com 2>/dev/null) || true
        echo "  GitHub: ${CODE:-000}"
        ;;
    stop|off)
        unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy 2>/dev/null
        for f in $(rc_files); do clean_rc "$f"; done
        command -v git >/dev/null 2>&1 && {
            git config --global --unset http.proxy 2>/dev/null
            git config --global --unset https.proxy 2>/dev/null
        }
        [ -f "$APT_FILE" ] && { sudo -n rm -f "$APT_FILE" 2>/dev/null || sudo rm -f "$APT_FILE" 2>/dev/null; }
        [ -f "$ENV_D_FILE" ] && rm -f "$ENV_D_FILE"

        echo "[代理已关闭]"
        RC_MARK="✓"; grep -qF "$MARK_B" "$HOME/.bashrc" 2>/dev/null || grep -qF "$MARK_LB" "$HOME/.bashrc" 2>/dev/null && RC_MARK="✗"
        GIT_MARK="✓"; [ -n "$(git config --global http.proxy 2>/dev/null)" ] && GIT_MARK="✗"
        APT_MARK="✓"; [ -f "$APT_FILE" ] && APT_MARK="✗（需要 sudo）"
        echo "  已清除代理: shell rc ${RC_MARK} | git ${GIT_MARK} | apt ${APT_MARK}"
        ;;
    status|st)
        echo "[环境] ${ENV_NAME}"
        if [ -n "${HTTP_PROXY:-}" ]; then
            echo "[代理已开启] ${HTTP_PROXY}"
        else
            echo "[代理当前 shell: 未开启]"
        fi
        for f in $(rc_files); do
            if grep -qF "$MARK_B" "$f" 2>/dev/null || grep -qF "$MARK_LB" "$f" 2>/dev/null; then
                echo "  $(basename "$f"): 已配置"
            else
                echo "  $(basename "$f"): 未配置"
            fi
        done
        GIT_V="$(git config --global http.proxy 2>/dev/null)"
        echo "  git: ${GIT_V:-未配置}"
        [ -f "$APT_FILE" ] && echo "  apt: 已配置 ($(head -1 "$APT_FILE" 2>/dev/null | grep -oE 'http://[^\"]+'))" || echo "  apt: 未配置"
        [ -f "$ENV_D_FILE" ] && echo "  environment.d: 已配置"
        EP="$(pick_endpoint || true)"
        echo "  探测可用代理: ${EP:-未发现}"
        ;;
    *)
        echo "用法: bash $0 start|stop|status"
        echo "  start   探测可达代理（宿主×端口自动匹配）并配置 shell rc / git / apt / dnf / env.d"
        echo "  stop    全部清除"
        echo "  status  查看当前状态与可用代理"
        echo "环境变量: PROXY_HOST=<IP> PROXY_PORT=<端口> 可跳过自动探测"
        ;;
esac
