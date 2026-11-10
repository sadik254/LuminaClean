# LuminaClean ⚡️
### The Lightweight, Free & Native macOS Junk Cleaner & Optimizer

**LuminaClean** is a modern, privacy-first, 100% native macOS cleaner application built in **Swift & SwiftUI**. It was created as a free, open alternative to commercial Mac cleaning apps that charge \$30–\$40/year subscriptions for routine filesystem pruning.

---

## 🚀 Key Features

* **⚡️ Native macOS Interface:** Built with modern SwiftUI, SF Symbols, dynamic ring gauges, and native Dark/Light mode support.
* **🛠 Developer Junk Purge:** Reclaim 20GB–80GB+ of hidden bloat:
  * Xcode DerivedData, Archives & iOS DeviceSupport symbols
  * CocoaPods, npm, Homebrew, and Gradle package caches
* **🧹 System & Application Caches:** Safely clear bloated caches from Spotify, Chrome, Slack, Discord, and user log files.
* **📦 App Leftovers Hunter:** Detects orphaned folders in `~/Library/Application Support` from applications that have already been uninstalled.
* **🗑 macOS Trash Can:** Quick check and purge of your Mac's `.Trash`.
* **🔍 Full Transparency:** Every detected item shows its path, size, and file count with a **"Reveal in Finder"** button so you can inspect before deleting.
* **🔒 100% Private & Offline:** Zero telemetry, no background analytics, no ads, and no external network connections.

---

## 📂 Project Architecture

```
LuminaClean/
├── Package.swift                    # Swift Package definition
├── bundle.sh                        # One-click native macOS .app bundler
├── LuminaClean.app/                 # Compiled macOS Application Bundle
└── Sources/
    └── LuminaClean/
        ├── LuminaClean.swift        # @main App Entry Point
        ├── Models/
        │   ├── CleanCategory.swift  # Categories enum (System, Dev, Leftovers, Trash)
        │   ├── DiskInfo.swift       # Storage capacity model & percentage helper
        │   └── JunkItem.swift       # Detected junk file/folder model
        ├── Services/
        │   ├── DiskSpaceService.swift  # Filesystem volume metrics service
        │   ├── ScannerEngine.swift     # High-speed asynchronous directory scanner
        │   └── CleaningEngine.swift    # Safe removal & cleanup service
        ├── ViewModels/
        │   └── AppViewModel.swift   # MainActor state management (@Observable)
        └── Views/
            ├── ContentView.swift        # Main NavigationSplitView
            ├── SidebarView.swift        # Sidebar navigation & disk meter
            ├── DashboardView.swift      # Overview tab with usage ring & quick tiles
            ├── CategoryDetailView.swift # Detailed list with selection & filters
            ├── ItemRowView.swift        # Item row with path & Finder disclosure
            └── SettingsView.swift       # Privacy & safety principles
```

---

## 🛠 How to Build & Run

### 1. Launch the Ready-Made App
You can immediately launch the compiled app bundle from the terminal:
```bash
open LuminaClean.app
```

### 2. Open in Xcode
To edit, preview, or debug in Xcode:
```bash
open Package.swift
```
Select the **LuminaClean** scheme and click **Run** (⌘R).

### 3. Rebuild the App Bundle
Whenever you make changes to the Swift code, run:
```bash
./bundle.sh
```
This builds an optimized release binary and bundles it into `LuminaClean.app`.

---

## 🛡 Safety Principles
LuminaClean is built with strict guardrails:
1. **Never touches SIP or system directories:** System binaries and operating system files are strictly protected.
2. **Personal files excluded:** Documents, Desktop, Photos, and user files are excluded from automated sweeps.
3. **Inspectable:** Every item has a magnifying glass button to reveal the actual directory in Finder.

---

## 📄 License
This project is open-source and released under the **[MIT License](LICENSE)**. Feel free to use, modify, and distribute it freely.
