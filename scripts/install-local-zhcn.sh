#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

NODE_VERSION="${OPENCLAW_NODE_VERSION:-v22.16.0}"
LOCAL_NODE_DIR="$HOME/.openclaw/node-${NODE_VERSION}"

echo "[openclaw-zhCN] 仓库目录: $ROOT_DIR"
echo "[openclaw-zhCN] 当前分支: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

ensure_local_node() {
  if [[ -x "$LOCAL_NODE_DIR/bin/node" && -x "$LOCAL_NODE_DIR/bin/npm" ]]; then
    echo "[openclaw-zhCN] 已检测到本地 Node：$LOCAL_NODE_DIR"
    export PATH="$LOCAL_NODE_DIR/bin:$PATH"
    return 0
  fi

  local arch_raw
  arch_raw="$(uname -m)"
  local arch="x64"
  if [[ "$arch_raw" == "arm64" || "$arch_raw" == "aarch64" ]]; then
    arch="arm64"
  fi

  local tarball="node-${NODE_VERSION}-darwin-${arch}.tar.gz"
  local url="https://nodejs.org/dist/${NODE_VERSION}/${tarball}"

  echo "[openclaw-zhCN] 未找到 npm，开始下载 Node ${NODE_VERSION} (${arch}) 到 ${LOCAL_NODE_DIR} ..."
  mkdir -p "$LOCAL_NODE_DIR"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  if ! curl -fL --retry 3 -o "$tmp/$tarball" "$url"; then
    cat <<EOF
[openclaw-zhCN] 下载 Node 失败：$url

可能原因：你的网络访问 nodejs.org 不通。

替代办法（任选其一）：
  1) 换网络后重试本脚本：bash scripts/install-local-zhcn.sh
  2) 自己装官方 Node 包后重试：https://nodejs.org/
EOF
    exit 1
  fi

  tar -xzf "$tmp/$tarball" -C "$LOCAL_NODE_DIR" --strip-components=1
  rm -rf "$tmp"
  trap - EXIT

  if [[ ! -x "$LOCAL_NODE_DIR/bin/node" ]]; then
    echo "[openclaw-zhCN] Node 解压后未发现可执行文件，安装失败。"
    exit 1
  fi

  export PATH="$LOCAL_NODE_DIR/bin:$PATH"
  echo "[openclaw-zhCN] 已把本地 Node 加入当前会话 PATH。"
}

if need_cmd npm; then
  ensure_local_node
fi

# Re-export PATH if local node exists, in case user already had it.
if [[ -x "$LOCAL_NODE_DIR/bin/node" ]]; then
  export PATH="$LOCAL_NODE_DIR/bin:$PATH"
fi

echo "[openclaw-zhCN] node: $(node -v)"
echo "[openclaw-zhCN] npm:  $(npm -v)"

if ! need_cmd corepack; then
  echo "[openclaw-zhCN] 启用 corepack ..."
  corepack enable >/dev/null 2>&1 || true
fi

echo "[openclaw-zhCN] 安装/启用 pnpm ..."
if command -v corepack >/dev/null 2>&1; then
  corepack prepare "pnpm@10.32.1" --activate
else
  npm i -g pnpm
fi

echo "[openclaw-zhCN] pnpm: $(pnpm -v)"

echo "[openclaw-zhCN] 安装依赖 (pnpm install) ..."
pnpm install

echo "[openclaw-zhCN] 构建 Control UI (pnpm ui:build) ..."
pnpm ui:build

echo "[openclaw-zhCN] 构建主项目 (pnpm build) ..."
pnpm build

echo "[openclaw-zhCN] 全局安装当前源码版本 (npm i -g .) ..."
npm i -g .

cat <<EOF

[openclaw-zhCN] 完成 ✅

如果 \`openclaw --version\` 提示找不到命令，把下面这一行加到你的 ~/.zshrc 末尾，然后新开一个终端：

  export PATH="$LOCAL_NODE_DIR/bin:\$PATH"

接着验证并启动：

  openclaw --version
  openclaw dashboard

EOF
