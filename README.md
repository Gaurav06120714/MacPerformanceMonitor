# MacPerformanceMonitor

A lightweight native macOS menu bar app that displays real-time system performance stats — CPU, RAM, GPU, display refresh rate, and network speed — directly in your menu bar.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Preview

```
CPU 17%  RAM 9.3G  GPU 19%  Hz 119  ↑1.2M ↓3.4M
```

Color coded live in your menu bar:
- 🟢 Green — normal (< 50%)
- 🟡 Yellow — moderate (50–80%)
- 🔴 Red — high (> 80%)
- 🔵 Cyan — display Hz
- 🟦 Teal/Blue — network upload/download

---

## Features

- **CPU usage** — real tick-delta via Mach kernel APIs
- **RAM usage** — actual GB used (e.g. `9.3G`) via `vm_statistics64`
- **GPU usage** — IOKit `IOAccelerator` device utilization %
- **Display Hz** — live refresh rate via `CVDisplayLink`
- **Network speed** — real-time upload/download MB/s via `getifaddrs`
- Click menu bar item → detailed dropdown with live graphs, top processes, controls
- No Dock icon — pure menu bar app
- Extremely low CPU overhead
- Auto-start at login via `launchd`

---

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools or Xcode

---

## Build & Run

```bash
git clone https://github.com/YOUR_USERNAME/MacPerformanceMonitor.git
cd MacPerformanceMonitor

swift build -c release
.build/release/MacPerformanceMonitor
```

---

## Auto-start at Login

Run once to launch automatically on every boot:

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

To stop: `launchctl unload ~/Library/LaunchAgents/com.MacPerformanceMonitor.plist`

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
        │   ├── MenuBarManager.swift
        │   ├── DropdownView.swift
        │   └── MiniGraphView.swift
        ├── Monitors/
        │   ├── SystemMonitor.swift
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

## Why FPS shows Hz not game FPS

macOS sandboxes each process — no global GPU present queue exists outside a running app (unlike Windows DXGI hooks used by MSI Afterburner). `CVDisplayLink` gives the display's active refresh rate. True per-game FPS from an external monitor is not possible on macOS without disabling SIP.

---

## License

MIT
