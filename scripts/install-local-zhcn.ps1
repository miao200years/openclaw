# OpenClaw 中文版 - Windows 一键安装脚本
# 使用方法（在仓库根目录的 PowerShell 里）:
#   powershell -ExecutionPolicy Bypass -File scripts\install-local-zhcn.ps1
#
# 如果需要换 Node 版本，可设置环境变量再跑：
#   $env:OPENCLAW_NODE_VERSION = "v22.16.0"

$ErrorActionPreference = "Stop"

# 移到仓库根目录
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptRoot "..")
Set-Location $RepoRoot

$NodeVersion = if ($env:OPENCLAW_NODE_VERSION) { $env:OPENCLAW_NODE_VERSION } else { "v22.16.0" }
$LocalNodeDir = Join-Path $env:USERPROFILE ".openclaw\node-$NodeVersion"

Write-Host "[openclaw-zhCN] 仓库目录: $RepoRoot"
try {
    $branch = (git rev-parse --abbrev-ref HEAD) 2>$null
    Write-Host "[openclaw-zhCN] 当前分支: $branch"
} catch {
    Write-Host "[openclaw-zhCN] 当前分支: unknown"
}

function Test-CommandExists($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-NodeArch() {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { return "arm64" }
    if ([Environment]::Is64BitOperatingSystem) { return "x64" }
    return "x86"
}

function Install-LocalNode() {
    if ((Test-Path "$LocalNodeDir\node.exe") -and (Test-Path "$LocalNodeDir\npm.cmd")) {
        Write-Host "[openclaw-zhCN] 已检测到本地 Node：$LocalNodeDir"
        $env:Path = "$LocalNodeDir;$env:Path"
        return
    }

    $arch = Get-NodeArch
    $tarball = "node-$NodeVersion-win-$arch.zip"
    $urls = @(
        "https://nodejs.org/dist/$NodeVersion/$tarball",
        "https://registry.npmmirror.com/-/binary/node/$NodeVersion/$tarball",
        "https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/$NodeVersion/$tarball",
        "https://mirrors.huaweicloud.com/nodejs/$NodeVersion/$tarball",
        "https://mirrors.aliyun.com/nodejs-release/$NodeVersion/$tarball"
    )

    Write-Host "[openclaw-zhCN] 未找到 npm，准备下载 Node $NodeVersion ($arch) 到 $LocalNodeDir ..."
    if (-not (Test-Path $LocalNodeDir)) {
        New-Item -ItemType Directory -Path $LocalNodeDir -Force | Out-Null
    }

    $tmpDir = Join-Path $env:TEMP "openclaw-node-$([guid]::NewGuid())"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $tmpZip = Join-Path $tmpDir $tarball

    $ok = $false
    foreach ($url in $urls) {
        Write-Host "[openclaw-zhCN] 尝试下载: $url"
        try {
            Invoke-WebRequest -Uri $url -OutFile $tmpZip -TimeoutSec 60 -UseBasicParsing
            if ((Test-Path $tmpZip) -and ((Get-Item $tmpZip).Length -gt 0)) {
                Write-Host "[openclaw-zhCN] 下载成功"
                $ok = $true
                break
            }
        } catch {
            Write-Host "[openclaw-zhCN] 该镜像不可用，尝试下一个..."
            if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force }
        }
    }

    if (-not $ok) {
        Write-Host ""
        Write-Host "[openclaw-zhCN] 下载 Node 失败：所有镜像都不可达。" -ForegroundColor Red
        Write-Host "可选方案："
        Write-Host "  1) 切换到能访问外网的网络后重试： powershell -ExecutionPolicy Bypass -File scripts\install-local-zhcn.ps1"
        Write-Host "  2) 自己下载 Node 后重试： https://nodejs.org/zh-cn/download/"
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Write-Host "[openclaw-zhCN] 解压 Node ..."
    $extractDir = Join-Path $tmpDir "extract"
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    Expand-Archive -LiteralPath $tmpZip -DestinationPath $extractDir -Force

    # zip 内是一层目录 node-vXX-win-arch/
    $nodeRoot = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    if (-not $nodeRoot) {
        Write-Host "[openclaw-zhCN] 解压后未找到 Node 目录，安装失败。" -ForegroundColor Red
        exit 1
    }

    Copy-Item -Path (Join-Path $nodeRoot.FullName "*") -Destination $LocalNodeDir -Recurse -Force
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path "$LocalNodeDir\node.exe")) {
        Write-Host "[openclaw-zhCN] Node 解压后未发现 node.exe，安装失败。" -ForegroundColor Red
        exit 1
    }

    $env:Path = "$LocalNodeDir;$env:Path"
    Write-Host "[openclaw-zhCN] 已把本地 Node 加入当前会话 PATH。"
}

if (-not (Test-CommandExists "npm")) {
    Install-LocalNode
}

if (Test-Path "$LocalNodeDir\node.exe") {
    $env:Path = "$LocalNodeDir;$env:Path"
}

Write-Host "[openclaw-zhCN] node: $(node -v)"
Write-Host "[openclaw-zhCN] npm:  $(npm -v)"

$NpmRegistry = if ($env:OPENCLAW_NPM_REGISTRY) { $env:OPENCLAW_NPM_REGISTRY } else { "https://registry.npmmirror.com" }
Write-Host "[openclaw-zhCN] npm registry: $NpmRegistry"
& npm config set registry $NpmRegistry | Out-Null

if (Test-CommandExists "corepack") {
    Write-Host "[openclaw-zhCN] 启用 corepack ..."
    corepack enable | Out-Null
}

Write-Host "[openclaw-zhCN] 安装/启用 pnpm ..."
if (Test-CommandExists "corepack") {
    corepack prepare "pnpm@10.32.1" --activate
} else {
    npm i -g pnpm
}

Write-Host "[openclaw-zhCN] pnpm: $(pnpm -v)"
& pnpm config set registry $NpmRegistry | Out-Null

Write-Host "[openclaw-zhCN] 安装依赖 (pnpm install) ..."
pnpm install

Write-Host "[openclaw-zhCN] 构建 Control UI (pnpm ui:build) ..."
pnpm ui:build

Write-Host "[openclaw-zhCN] 构建主项目 (pnpm build) ..."
pnpm build

Write-Host "[openclaw-zhCN] 全局安装当前源码版本 (npm i -g .) ..."
npm i -g .

Write-Host ""
Write-Host "[openclaw-zhCN] 完成"
Write-Host ""
Write-Host "如果 ``openclaw --version`` 提示找不到命令，请把以下路径加入系统/用户 PATH："
Write-Host "  $LocalNodeDir"
Write-Host ""
Write-Host "接着验证并启动："
Write-Host "  openclaw --version"
Write-Host "  openclaw dashboard"
