# CodexLite

CodexLite is a minimalist, native macOS menu bar application designed to display and monitor your Codex usage quota.

## Key Features
- **Native & Lightweight**: Built entirely with Swift/SwiftUI, completely dropping the heavy Electron framework. It runs purely in the background as a status bar app with zero redundant UI.
- **Clear Quota Display**: Instantly view your 5-hour and 1-week usage quota directly on the menu bar.
- **Used/Remaining Toggle**: Easily toggle between viewing your "Used Quota" and "Remaining Quota" from the dropdown menu.
- **Seamless Multi-Model Support**: Dynamically parses all models supported by the Codex app-server (such as Codex, GPT-5.3-Codex-Spark, Anti-gravity, etc.), allowing you to switch between them effortlessly.
- **Auto Refresh**: Silently updates your quota data in the background every 4 minutes.

## Installation

1. The compiled application is available as `CodexLite.app` in the `CodexLite` directory.
2. You can double-click to run it directly. If you want it to launch automatically at startup:
   - Drag `CodexLite.app` into your `Applications` folder.
   - Open macOS **System Settings** -> **General** -> **Login Items**.
   - Add `CodexLite.app` to the "Open at Login" list.

## How to Modify and Build

All source code is contained within `CodexLite/Sources/app.swift`. The core logic is clear and highly readable. If you wish to customize the display format, refresh interval, or add new menu items:

1. Edit the `CodexLite/Sources/app.swift` file.
2. Run the build script to recompile and package the app:
   ```bash
   cd CodexLite
   bash build.sh
   ```
3. The build script will automatically output a fully functional `CodexLite.app` bundle containing the necessary `Info.plist` to run silently in the background.

## Dependencies
This application has zero external package dependencies. It compiles using the built-in macOS Swift compiler (`swiftc`). During runtime, it relies on the local `Codex.app` CLI (`app-server`) to fetch the authentic quota data.
