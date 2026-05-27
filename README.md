# MacPerformanceMonitor

A lightweight native macOS menu bar app showing real-time system stats — CPU, RAM, GPU, display Hz, and network speed — as pure color-coded numbers directly in your menu bar.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Preview

```
12% | 9.2G | 2% | 120 | ↑0K ↓0K   🌙
```

No labels. Just numbers. Color tells you everything:

| Position | Metric | Color |
|---|---|---|
| 1st | CPU usage | 🟢 Green / 🟡 Yellow / 🔴 Red |
| 2nd | RAM used (GB) | 🟢 Green |
| 3rd | GPU usage | 🟢 Green / 🟡 Yellow / 🔴 Red |
| 4th | Display Hz | 🔵 Cyan |
| 5th | Network ↑↓ | 🟦 Teal / Blue |

---

## Features

- Pure numbers — no clutter, no labels
- **CPU** — real tick-delta via Mach kernel APIs
- **RAM** — actual GB used via `vm_statistics64`
- **GPU** — IOKit `IOAccelerator` device utilization %
- **Hz** — live display refresh rate via `CVDisplayLink`
- **Network** — real-time upload/download MB/s via `getifaddrs`
- Click menu bar → detailed dropdown with graphs, top processes, controls
- No Dock icon — pure menu bar app
- Extremely low CPU overhead (~0.1%)
- Works alongside other menu bar apps

---

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools

Install Xcode CLT if needed:
```bash
xcode-select --install
```

---

## Build & Run

```bash
git clone https://github.com/Gaurav06120714/MacPerformanceMonitor.git
cd MacPerformanceMonitor

swift build -c release
.build/release/MacPerformanceMonitor
```

---

## Auto-start at Login

Run once — app launches automatically on every boot:

```bash
cat > ~/Library/LaunchAgents/com.MacPerformanceMonitor.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.MacPerformanceMonitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/MacPerformanceMonitor/.build/release/MacPerformanceMonitor</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.MacPerformanceMonitor.plist
```

> Replace `/path/to/` with your actual project path.

To remove: `launchctl unload ~/Library/LaunchAgents/com.MacPerformanceMonitor.plist`

---

## Project Structure

```
MacPerformanceMonitor/
├── Package.swift
├── build.sh
├── README.md
└── MacPerformanceMonitor/
    └── Sources/
        ├── App/
        │   ├── MacPerformanceMonitorApp.swift
        │   └── AppDelegate.swift
        ├── MenuBar/
        │   ├── MenuBarManager.swift       ← menu bar title + popover
        │   ├── DropdownView.swift         ← detail panel on click
        │   └── MiniGraphView.swift        ← sparkline graphs
        ├── Monitors/
        │   ├── SystemMonitor.swift        ← aggregator
        │   ├── CPUMonitor.swift
        │   ├── RAMMonitor.swift
        │   ├── GPUMonitor.swift
        │   ├── FPSMonitor.swift
        │   └── NetworkMonitor.swift
        ├── Settings/
        │   ├── SettingsView.swift
        │   └── AppPreferences.swift
        └── Utilities/
            ├── LaunchAtLogin.swift
            └── Logger.swift
```

---

## Why Hz instead of FPS

macOS sandboxes each process — there is no global GPU present queue accessible from outside a running app (unlike Windows DXGI hooks used by MSI Afterburner/RTSS). `CVDisplayLink` gives the display's active refresh rate, which is the ceiling FPS any app can hit. True per-game FPS from an external monitor is not possible on macOS without disabling SIP.

---

## No Special Permissions Required

All APIs used (Mach host stats, IOKit, getifaddrs) are available to any app without special entitlements.

---

## License

MIT
“Pull Shark Bronze progress”
