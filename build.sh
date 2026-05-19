#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building MacPerformanceMonitor..."
swift build -c release 2>&1

echo ""
echo "Build complete: .build/release/MacPerformanceMonitor"
echo ""
echo "Run with:"
echo "  .build/release/MacPerformanceMonitor"
echo ""
echo "Or package as .app:"
echo "  mkdir -p MacPerformanceMonitor.app/Contents/MacOS"
echo "  cp .build/release/MacPerformanceMonitor MacPerformanceMonitor.app/Contents/MacOS/"
echo "  cp MacPerformanceMonitor/Resources/Info.plist MacPerformanceMonitor.app/Contents/"
echo "  open MacPerformanceMonitor.app"
