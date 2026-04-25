#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[openclaw-zhCN] repo: $ROOT_DIR"
echo "[openclaw-zhCN] branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

if need_cmd npm; then
  echo "[openclaw-zhCN] npm 不存在：需要一个带 npm 的 Node 安装。"
  if command -v brew >/dev/null 2>&1; then
    echo "[openclaw-zhCN] 使用 Homebrew 安装 node（含 npm/corepack）..."
    brew install node
  else
    cat <<'EOF'
[openclaw-zhCN] 检测到你当前环境只有 node，没有 npm/corepack。
请先安装以下其一：

1) Homebrew（推荐）
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install node

2) 或直接安装官方 Node（自带 npm）
   https://nodejs.org/

安装完成后重新打开终端，再重新运行本脚本：
   bash scripts/install-local-zhcn.sh
EOF
    exit 1
  fi
fi

echo "[openclaw-zhCN] node: $(node -v)"
echo "[openclaw-zhCN] npm:  $(npm -v)"

if need_cmd corepack; then
  echo "[openclaw-zhCN] corepack 不存在，尝试继续（但推荐升级到带 corepack 的 Node）。"
else
  echo "[openclaw-zhCN] 启用 corepack..."
  corepack enable >/dev/null 2>&1 || true
fi

echo "[openclaw-zhCN] 安装/启用 pnpm..."
if command -v corepack >/dev/null 2>&1; then
  corepack prepare "pnpm@10.32.1" --activate
else
  npm i -g pnpm
fi

echo "[openclaw-zhCN] pnpm: $(pnpm -v)"

echo "[openclaw-zhCN] 安装依赖..."
pnpm install

echo "[openclaw-zhCN] 构建 Control UI..."
pnpm ui:build

echo "[openclaw-zhCN] 构建主项目..."
pnpm build

echo "[openclaw-zhCN] 本地全局安装（使用你当前源码构建产物）..."
pnpm -w add -g .

echo "[openclaw-zhCN] 完成。验证："
echo "  openclaw --version"
echo "  openclaw dashboard"

