#Requires -Version 5.1
# ============================================================
# dev-env-setup - Basic dev environment for Windows
# Run in PowerShell:
#   Set-ExecutionPolicy -Scope Process Bypass; .\setup-windows.ps1
# Switches: -SkipInstall (configs only) / -NoAI (skip opencode-ai)
# ============================================================
param([switch]$SkipInstall, [switch]$NoAI)

$ErrorActionPreference = "Continue"
$Repo   = $PSScriptRoot
$Backup = Join-Path $HOME ".dev-env-setup-backup"
New-Item -ItemType Directory -Force -Path $Backup | Out-Null
$script:Oks = 0; $script:Fails = @()

function OK([string]$m)   { $script:Oks++; Write-Host "[ok] $m" -ForegroundColor Green }
function FAIL([string]$m) { $script:Fails += $m; Write-Host "[FAIL] $m" -ForegroundColor Red }
function WARN([string]$m) { Write-Host "[i] $m" -ForegroundColor Yellow }

# ---------- Phase 1: tools via winget ----------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    FAIL "winget not found (install 'App Installer' from Microsoft Store)"; exit 1
}
if ($SkipInstall) {
    WARN "-SkipInstall: skipping software installation"
} else {
    Write-Host "== Phase 1/3: install tools (winget) ==" -ForegroundColor Cyan
    foreach ($id in @("Git.Git","GitHub.cli","OpenJS.NodeJS.LTS","BurntSushi.ripgrep.MSVC","jqlang.jq","astral-sh.uv")) {
        winget install -e --id $id --accept-source-agreements --accept-package-agreements --silent | Out-Null
        if ($LASTEXITCODE -eq 0) { OK $id } else { FAIL $id }
    }
}
# refresh PATH for current session
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")

# ---------- Phase 2: npm globals ----------
Write-Host "== Phase 2/3: npm globals ==" -ForegroundColor Cyan
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm config set registry https://registry.npmmirror.com
    if ($LASTEXITCODE -eq 0) { OK "npm registry -> npmmirror" } else { FAIL "npm registry" }
    npm install -g pnpm bun --silent | Out-Null
    if ($LASTEXITCODE -eq 0) { OK "pnpm / bun" } else { FAIL "pnpm / bun" }
    if (-not $NoAI) {
        npm install -g opencode-ai --silent | Out-Null
        if ($LASTEXITCODE -eq 0) { OK "opencode-ai" } else { FAIL "opencode-ai" }
    }
} else {
    WARN "npm not on PATH yet (fresh install) - reopen terminal and re-run with -SkipInstall for npm globals"
}

# ---------- Phase 3: config deployment ----------
Write-Host "== Phase 3/3: deploy configs ==" -ForegroundColor Cyan
function Backup-Deploy([string]$src, [string]$dst) {
    $dir = Split-Path $dst -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if (Test-Path $dst) { Copy-Item $dst (Join-Path $Backup ((Split-Path $dst -Leaf) + ".bak")) -Force }
    Copy-Item $src $dst -Force
}

Backup-Deploy (Join-Path $Repo "config\gitconfig") (Join-Path $HOME ".gitconfig");        OK "gitconfig"
Set-Content -Path (Join-Path $HOME ".npmrc") -Value "registry=https://registry.npmmirror.com" -Encoding ascii; OK "npmrc"
Backup-Deploy (Join-Path $Repo "config\git-ignore") (Join-Path $HOME ".config\git\ignore"); OK "git ignore"
Backup-Deploy (Join-Path $Repo "config\gh\config.yml") (Join-Path $HOME ".config\gh\config.yml"); OK "gh config (run: gh auth login)"

foreach ($f in @("opencode.json","opencode.jsonc","oh-my-openagent.json","tui.json","package.json","package-lock.json")) {
    Backup-Deploy (Join-Path $Repo "config\opencode\$f") (Join-Path $HOME ".config\opencode\$f")
}
OK "opencode configs (run: opencode auth login)"
if (-not (Test-Path "$HOME\.config\opencode\skills")) {
    Copy-Item (Join-Path $Repo "config\opencode\skills") "$HOME\.config\opencode\skills" -Recurse; OK "opencode skills x6"
}

# skills repo
$SkillDir = Join-Path $HOME "repos\skill"
if (Test-Path $SkillDir) {
    OK "skills repo exists: $SkillDir"
} else {
    New-Item -ItemType Directory -Force -Path (Join-Path $HOME "repos") | Out-Null
    git clone --depth 1 https://github.com/anbeime/skill.git $SkillDir 2>$null
    if ($LASTEXITCODE -eq 0) { OK "skills repo cloned" } else { WARN "skills repo clone failed (manual: git clone https://github.com/anbeime/skill.git ~\repos\skill)" }
}

# patch opencode.jsonc skills path (forward slashes for opencode)
$jsonc = Join-Path $HOME ".config\opencode\opencode.jsonc"
if (Test-Path $jsonc) {
    $skillPath = ($HOME -replace '\\','/') + "/repos/skill/skills"
    (Get-Content $jsonc -Raw) -replace '"paths": \["[^"]*"\]', ('"paths": ["' + $skillPath + '"]') |
        Set-Content $jsonc -NoNewline -Encoding utf8
    OK "opencode.jsonc skills path -> $skillPath"
}

# ---------- summary ----------
Write-Host "" 
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Done: $($script:Oks) ok / $($script:Fails.Count) failed"
foreach ($f in $script:Fails) { Write-Host "  [FAIL] $f" -ForegroundColor Red }
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Next steps:"
Write-Host "   1. Reopen terminal (refresh PATH)"
Write-Host "   2. gh auth login          # GitHub credentials (not included in this repo)"
Write-Host "   3. opencode auth login    # AI provider keys (not included in this repo)"
Write-Host " Backup dir: $Backup"
