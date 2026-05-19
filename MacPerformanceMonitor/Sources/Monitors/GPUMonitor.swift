import IOKit
import Foundation

/// Reads GPU utilisation via IOKit's IOAccelerator service.
///
/// Availability notes:
///   - On Intel Macs this usually works and exposes "Device Utilization %".
///   - On Apple Silicon (M-series) Apple does not expose GPU utilisation through
///     the standard IOAccelerator path from outside the process. This monitor
///     returns nil gracefully when no data is available.
///   - The "PerformanceStatistics" dictionary is the standard location;
///     "GPU Activity(%)" is a fallback key used on some configurations.
final class GPUMonitor {

    init() {}

    // MARK: - Public API

    /// Returns GPU utilisation as a percentage 0–100, or nil if unavailable.
    func gpuUsage() -> Double? {
        var iterator: io_iterator_t = 0

        // Match against the IOAccelerator class, which represents GPU drivers.
        guard let matchingDict = IOServiceMatching("IOAccelerator") else {
            return nil
        }

        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        guard kr == KERN_SUCCESS else {
            monitorLogger.debug("IOServiceGetMatchingServices failed: \(kr)")
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var bestUsage: Double? = nil

        // Iterate over all found GPU accelerator services.
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            // Retrieve the full property dictionary for this service.
            var cfProperties: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(
                service,
                &cfProperties,
                kCFAllocatorDefault,
                0
            )
            guard propResult == KERN_SUCCESS,
                  let properties = cfProperties?.takeRetainedValue() as? [String: Any]
            else { continue }

            // The performance stats live inside the "PerformanceStatistics" sub-dict.
            if let perfStats = properties["PerformanceStatistics"] as? [String: Any] {
                let usage = readUtilization(from: perfStats)
                if let u = usage {
                    // Take the highest value across all GPU services (e.g. discrete + integrated).
                    bestUsage = max(bestUsage ?? 0.0, u)
                }
            }
        }

        return bestUsage
    }

    // MARK: - Private helpers

    private func readUtilization(from dict: [String: Any]) -> Double? {
        // Primary key used on most Intel Macs.
        if let val = dict["Device Utilization %"] as? Double {
            return clamp(val)
        }
        if let val = dict["Device Utilization %"] as? Int {
            return clamp(Double(val))
        }

        // Fallback key used on some AMD configurations.
        if let val = dict["GPU Activity(%)"] as? Double {
            return clamp(val)
        }
        if let val = dict["GPU Activity(%)"] as? Int {
            return clamp(Double(val))
        }

        // Some M-series machines expose a renderer utilisation key.
        if let val = dict["Renderer Utilization %"] as? Double {
            return clamp(val)
        }
        if let val = dict["Renderer Utilization %"] as? Int {
            return clamp(Double(val))
        }

        return nil
    }

    private func clamp(_ value: Double) -> Double {
        max(0.0, min(100.0, value))
    }
}
