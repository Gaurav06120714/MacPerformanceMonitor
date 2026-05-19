import AppKit

/// Wires the application together.
///
/// - Hides the Dock icon (LSUIElement = true in Info.plist handles this at launch,
///   but we also call `setActivationPolicy(.accessory)` here for robustness).
/// - Creates `SystemMonitor`, `MenuBarManager`, and starts sampling.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // These must be retained for the lifetime of the app.
    var systemMonitor  = SystemMonitor()
    var menuBarManager: MenuBarManager?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no Dock icon appears regardless of Info.plist state.
        NSApp.setActivationPolicy(.accessory)

        // Wire menu bar manager to the shared monitor.
        menuBarManager = MenuBarManager(monitor: systemMonitor)
        menuBarManager?.setup()

        // Start background sampling threads.
        systemMonitor.start()

        appLogger.info("MacPerformanceMonitor launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        systemMonitor.stop()
        menuBarManager?.teardown()
        appLogger.info("MacPerformanceMonitor terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // We are a menu-bar-only app; closing settings/windows should not quit.
        return false
    }
}
