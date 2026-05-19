import ServiceManagement
import OSLog

/// Manages the "Launch at Login" behavior using SMAppService (macOS 13+).
/// The app must be code-signed for SMAppService to work in production.
/// In development builds (unsigned), registration will fail silently.
struct LaunchAtLogin {

    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        get {
            let status = SMAppService.mainApp.status
            return status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                    appLogger.info("Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    appLogger.info("Launch at login disabled")
                }
            } catch {
                appLogger.error("Failed to update launch at login: \(error.localizedDescription)")
            }
        }
    }

    /// Human-readable status string for display in UI.
    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:       return "Enabled"
        case .requiresApproval: return "Requires Approval"
        case .notFound:      return "Not Found"
        case .notRegistered: return "Not Registered"
        @unknown default:    return "Unknown"
        }
    }
}
