<p align="center">
    <picture>
        <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/openclaw/openclaw/main/docs/assets/openclaw-logo-text-dark.svg">
        <img src="https://raw.githubusercontent.com/openclaw/openclaw/main/docs/assets/openclaw-logo-text.svg" alt="OpenClaw" width="500">
    </picture>
</p>

# 🦞 OpenClaw — 个人 AI 助手（简体中文）

OpenClaw 是一个你可以**自己部署/自己掌控**的个人 AI 助手与网关（Gateway）：它把你常用的聊天渠道（如 Telegram、WhatsApp、Slack、Discord 等）连接到 AI 智能体，并提供 CLI 与 Web 控制界面。

- **仓库内中文文档入口**: [`docs/zh-CN/index.md`](docs/zh-CN/index.md)
- **GitHub 直接可读的中文快速开始**（推荐从这里看）: [`docs/zh-CN/GITHUB.md`](docs/zh-CN/GITHUB.md)
- **入门指南（中文）**: [`docs/zh-CN/start/getting-started.md`](docs/zh-CN/start/getting-started.md)

## 一键安装（自动构建你这版中文 OpenClaw）

- **macOS / Linux**:

```bash
cd <仓库根目录>
bash scripts/install-local-zhcn.sh
```

- **Windows (PowerShell)**:

```powershell
cd <仓库根目录>
powershell -ExecutionPolicy Bypass -File scripts\install-local-zhcn.ps1
```

脚本会自己下载 Node（含国内镜像回退）、安装 pnpm、构建并把 `openclaw` 全局安装。

## 最快可用路径（推荐）

> 目标：不要求你先配置任何聊天渠道，先把 Gateway 跑起来并能在浏览器里聊天。

运行环境：**Node 24（推荐）** 或 **Node 22.16+**。

```bash
npm install -g openclaw@latest
# 或：pnpm add -g openclaw@latest

openclaw onboard --install-daemon

openclaw dashboard
```

本地默认地址通常是：`http://127.0.0.1:18789/`

## 下一步（中文文档，按任务走）

- **快速开始**: [`docs/zh-CN/start/quickstart.md`](docs/zh-CN/start/quickstart.md)
- **新手引导（Wizard / Onboard）**: [`docs/zh-CN/start/wizard.md`](docs/zh-CN/start/wizard.md)
- **Web 控制界面**: [`docs/zh-CN/web/control-ui.md`](docs/zh-CN/web/control-ui.md)
- **安装方式总览（Docker/Nix/更新/卸载等）**: [`docs/zh-CN/install/index.md`](docs/zh-CN/install/index.md)
- **常见问题**: [`docs/zh-CN/help/faq.md`](docs/zh-CN/help/faq.md)

## 安全提示（强烈建议先看）

OpenClaw 会连接真实聊天入口，把外部消息当作**不可信输入**来处理。

- 中文安全指南: [`docs/zh-CN/gateway/security/index.md`](docs/zh-CN/gateway/security/index.md)

