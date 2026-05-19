import SwiftUI

/// Application entry point.
///
/// We use `NSApplicationDelegateAdaptor` to bridge SwiftUI's `@main` lifecycle
/// into AppKit so we can use `NSStatusItem` and other AppKit-only APIs that
/// SwiftUI's `MenuBarExtra` does not yet fully support (e.g. attributed titles,
/// custom popover positioning, CVDisplayLink).
///
/// The SwiftUI `App` body is intentionally empty — the entire UI lives inside
/// `MenuBarManager` (which creates the `NSStatusItem`) and `DropdownView` (shown
/// in the `NSPopover`).
@main
struct MacPerformanceMonitorApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // An empty Settings scene is the minimum required by SwiftUI on macOS.
        // It prevents SwiftUI from creating a default "WindowGroup" window.
        Settings {
            EmptyView()
        }
    }
}
