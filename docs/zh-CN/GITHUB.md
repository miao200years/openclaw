# OpenClaw（简体中文，GitHub 版）

> 这份文档是为了 **在 GitHub 里直接阅读** 而写的纯 Markdown 版本。  
> `docs/zh-CN/` 下其它文档很多是给官网文档站渲染用的（含组件语法与站点绝对路径），在 GitHub 预览里可能会出现“步骤不显示/图片打不开”的情况。

## 最快可用（不配置任何聊天渠道）

目标：本地启动 Gateway，并在浏览器 Control UI 里聊天。

### 1) 安装

运行环境：**Node 24（推荐）** 或 **Node 22.16+**。

```bash
npm install -g openclaw@latest
# 或：pnpm add -g openclaw@latest
```

### 2) 新手引导（推荐）

```bash
openclaw onboard --install-daemon
```

### 3) 打开控制界面

```bash
openclaw dashboard
```

常见本地地址：`http://127.0.0.1:18789/`

### 4) 前台启动（可选：方便看日志）

```bash
openclaw gateway --port 18789 --verbose
```

## 常用命令（中文速查）

```bash
# 检查网关服务状态（如果你用 onboard 安装了后台服务）
openclaw gateway status

# 体检/诊断
openclaw doctor

# 发送消息（需要你先配置好对应渠道）
openclaw message send --target +15555550123 --message "你好，OpenClaw"
```

## 图片为什么会“打不开”？

如果你在 GitHub 里看的是 `docs/zh-CN/index.md` 等页面，它里面会出现这种路径：

- `/assets/...`
- `/whatsapp-openclaw.jpg`

这些是 **官网文档站** 的站点根路径写法，在 GitHub 预览里不会自动映射到仓库文件，所以看起来就像“图片都打不开”。

在 GitHub 里请优先使用：

- 仓库相对路径：`../assets/...` 或 `../images/...`
- 或者 Raw 链接（`raw.githubusercontent.com`）

例如（仓库内可用的 logo）：

![OpenClaw](../assets/openclaw-logo-text.svg)

## 下一步（继续看更完整的中文文档）

> 下面这些页面在 GitHub 里可能仍会因为组件语法而显示不完整；但内容本身是中文的。

- 入门指南：`start/getting-started.md`
- 快速开始：`start/quickstart.md`
- 新手引导：`start/wizard.md`
- Web 控制界面：`web/control-ui.md`
- 常见问题：`help/faq.md`

