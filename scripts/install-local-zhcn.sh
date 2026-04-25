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
  local urls=(
    "https://nodejs.org/dist/${NODE_VERSION}/${tarball}"
    "https://registry.npmmirror.com/-/binary/node/${NODE_VERSION}/${tarball}"
    "https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/${NODE_VERSION}/${tarball}"
    "https://mirrors.huaweicloud.com/nodejs/${NODE_VERSION}/${tarball}"
    "https://mirrors.aliyun.com/nodejs-release/${NODE_VERSION}/${tarball}"
  )

  echo "[openclaw-zhCN] 未找到 npm，准备下载 Node ${NODE_VERSION} (${arch}) 到 ${LOCAL_NODE_DIR} ..."
  mkdir -p "$LOCAL_NODE_DIR"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  local ok=0
  local url
  for url in "${urls[@]}"; do
    echo "[openclaw-zhCN] 尝试下载: $url"
    if curl -fL \
        --connect-timeout 10 \
        --max-time 600 \
        --retry 2 --retry-delay 2 \
        --progress-bar \
        -o "$tmp/$tarball" "$url"; then
      echo "[openclaw-zhCN] 下载成功 ✅"
      ok=1
      break
    else
      echo "[openclaw-zhCN] 该镜像不可用，尝试下一个..."
      rm -f "$tmp/$tarball"
    fi
  done

  if [[ "$ok" -ne 1 ]]; then
    cat <<EOF
[openclaw-zhCN] 下载 Node 失败：所有镜像都不可达。

可能原因：
  - 你当前处于受限网络，无法访问 nodejs.org / npmmirror / 清华 / 华为云 / 阿里云
  - 公司/校园网代理拦截了上述域名

可选方案：
  1) 切换到能访问外网的网络（手机热点等）后重试：
       bash scripts/install-local-zhcn.sh
  2) 自己下载 Node 后再运行本脚本：
       去官网 https://nodejs.org/zh-cn/download/ 下载 macOS 安装包并安装
       然后重试：
         bash scripts/install-local-zhcn.sh
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

if [[ -x "$LOCAL_NODE_DIR/bin/node" ]]; then
  export PATH="$LOCAL_NODE_DIR/bin:$PATH"
fi

echo "[openclaw-zhCN] node: $(node -v)"
echo "[openclaw-zhCN] npm:  $(npm -v)"

# Use China npm mirror to speed up dependency installs.
NPM_REGISTRY="${OPENCLAW_NPM_REGISTRY:-https://registry.npmmirror.com}"
echo "[openclaw-zhCN] npm registry: $NPM_REGISTRY"
npm config set registry "$NPM_REGISTRY" >/dev/null 2>&1 || true

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
pnpm config set registry "$NPM_REGISTRY" >/dev/null 2>&1 || true

echo "[openclaw-zhCN] 安装依赖 (pnpm install) ..."
pnpm install

echo "[openclaw-zhCN] 构建主项目 (pnpm build) ..."
pnpm build

echo "[openclaw-zhCN] 构建 Control UI (pnpm ui:build) ..."
pnpm ui:build

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
