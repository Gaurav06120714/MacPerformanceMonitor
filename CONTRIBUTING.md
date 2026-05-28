# Contributing to MacPerformanceMonitor

Thanks for your interest in contributing! This guide covers setup and conventions.

## Getting Started

### Requirements
- macOS 13+ (Ventura or later)
- Xcode 15+
- Swift 5.9+

### Build
```bash
swift build
swift run
```

### Run tests
```bash
swift test
```

## Project Structure

```
MacPerformanceMonitor/
├── MacPerformanceMonitor/Sources/
│   ├── App/              ← AppDelegate, entry point
│   ├── MenuBar/          ← Status item, popover, dropdown UI
│   ├── Monitors/         ← CPU, RAM, GPU, FPS, Network samplers
│   ├── Settings/         ← Preferences UI and AppPreferences
│   └── Utilities/        ← Logger, LaunchAtLogin
└── Package.swift
```

## Commit Style
Follow conventional commits:
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code cleanup
- `docs:` documentation only
- `perf:` performance improvement

## Pull Requests
1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Commit your changes
4. Open a PR against `main`
