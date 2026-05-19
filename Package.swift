// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPerformanceMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacPerformanceMonitor",
            path: "MacPerformanceMonitor/Sources",
            resources: [.process("../Resources")],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("Metal"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
