# CodexLite

CodexLite 是一个极简的 macOS 原生菜单栏应用，专门用于显示和监控你的 Codex 使用额度（Quota）。

## 核心特性
- **纯原生 & 极简**：使用 Swift/SwiftUI 开发，抛弃了笨重的 Electron 框架。它作为纯后台应用运行在状态栏，毫无冗余 UI。
- **直观的额度显示**：在菜单栏直接展示 5 小时 和 1 周 的配额信息。
- **剩余/已用切换**：你可以自由切换是查看“已用额度”还是“剩余额度”。
- **多模型无缝切换**：动态解析 Codex app-server 支持的所有模型（如 Codex、GPT-5.3-Codex-Spark、Anti-gravity 等），可自由选择监控。
- **自动刷新**：每 4 分钟在后台静默刷新数据。

## 安装说明

1. 编译好的应用位于本目录：`CodexLite.app`
2. 可以直接双击运行。如果你希望开机自启动：
   - 将 `CodexLite.app` 拖入 `应用程序`（Applications）文件夹。
   - 打开 macOS 的 **系统设置** -> **通用** -> **登录项**。
   - 将 `CodexLite.app` 添加到“打开时启动”列表中即可。

## 如何修改和构建

应用的源代码全部集中在 `Sources/app.swift` 中，核心逻辑清晰易读。如果你需要自定义显示格式、刷新时间，或者添加新的菜单项：

1. 编辑 `Sources/app.swift` 文件。
2. 运行构建脚本进行重新编译打包：
   ```bash
   bash build.sh
   ```
3. 构建脚本会自动打包出拥有完整 Info.plist 的 `CodexLite.app` 应用程序。

## 依赖关系
本应用没有任何外部包依赖，直接使用 macOS 自带的 Swift 编译器 (`swiftc`) 即可完成构建。运行过程中，它会通过本地的 `Codex.app` 提供的 CLI (`app-server`) 获取真实的配额数据。
