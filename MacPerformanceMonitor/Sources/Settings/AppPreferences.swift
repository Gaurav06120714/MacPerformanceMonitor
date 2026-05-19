import Foundation

// MARK: - UserDefault property wrapper

/// A property wrapper that persists values in UserDefaults.standard.
/// Supports any type that conforms to `Codable` as well as all
/// UserDefaults-native types (Bool, Int, Double, String, etc.).
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let store: UserDefaults

    init(_ key: String, defaultValue: T, store: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    var wrappedValue: T {
        get {
            guard let value = store.object(forKey: key) as? T else {
                return defaultValue
            }
            return value
        }
        set {
            store.set(newValue, forKey: key)
        }
    }

    /// Projected value exposes the key for observation with KVO / Combine if needed.
    var projectedValue: String { key }
}

// MARK: - AppPreferences

/// Centralised, singleton preferences store backed by UserDefaults.
/// Access via `AppPreferences.shared`.
final class AppPreferences {
    static let shared = AppPreferences()

    private init() {}

    // MARK: Refresh rate

    /// Monitoring refresh interval in seconds. Valid values: 0.5, 1.0, 2.0.
    @UserDefault("refreshInterval", defaultValue: 1.0)
    var refreshInterval: Double

    // MARK: Visibility toggles

    /// Whether to show GPU utilisation in the menu bar and dropdown.
    @UserDefault("showGPU", defaultValue: true)
    var showGPU: Bool

    /// Whether to show the display VSYNC rate (labelled "FPS") in the menu bar.
    @UserDefault("showFPS", defaultValue: true)
    var showFPS: Bool

    /// Whether to show RAM usage in the menu bar title.
    @UserDefault("showRAM", defaultValue: true)
    var showRAM: Bool

    /// Whether to show CPU usage in the menu bar title.
    @UserDefault("showCPU", defaultValue: true)
    var showCPU: Bool

    // MARK: Menu bar format

    /// Whether to show percentage symbols after numbers.
    @UserDefault("showPercentSign", defaultValue: true)
    var showPercentSign: Bool

    // MARK: Helpers

    /// Clamp and save a new refresh interval, only accepting known-good values.
    func setRefreshInterval(_ seconds: Double) {
        let allowed: [Double] = [0.5, 1.0, 2.0]
        refreshInterval = allowed.contains(seconds) ? seconds : 1.0
    }
}
