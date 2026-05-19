import Darwin
import Foundation

/// Reads system-wide CPU utilisation via the Mach `host_statistics` API.
///
/// How it works:
///   - `host_statistics(HOST_CPU_LOAD_INFO)` returns cumulative tick counts for each
///     CPU state (user, system, idle, nice) since boot.
///   - Between two samples we compute the delta for each state.
///   - Usage = (user_delta + system_delta + nice_delta) / total_delta * 100
///
/// The first call always returns 0 because there is no previous sample to diff against.
final class CPUMonitor {

    // Stored tick counts from the previous sample.
    private var previousInfo: host_cpu_load_info?

    init() {}

    /// Returns current CPU utilisation in the range 0–100.
    /// Returns 0.0 on the first call (no previous sample available).
    func cpuUsage() -> Double {
        var info = host_cpu_load_info()
        // The count must be expressed in units of integer_t, not bytes.
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size
        )

        let kr: kern_return_t = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPtr, &count)
            }
        }

        guard kr == KERN_SUCCESS else {
            monitorLogger.error("host_statistics(HOST_CPU_LOAD_INFO) failed: \(kr)")
            return 0.0
        }

        defer { previousInfo = info }

        guard let prev = previousInfo else {
            // First sample — nothing to diff against.
            return 0.0
        }

        // Compute per-state deltas.
        let userDelta   = Double(info.cpu_ticks.0) - Double(prev.cpu_ticks.0)  // CPU_STATE_USER
        let systemDelta = Double(info.cpu_ticks.1) - Double(prev.cpu_ticks.1)  // CPU_STATE_SYSTEM
        let idleDelta   = Double(info.cpu_ticks.2) - Double(prev.cpu_ticks.2)  // CPU_STATE_IDLE
        let niceDelta   = Double(info.cpu_ticks.3) - Double(prev.cpu_ticks.3)  // CPU_STATE_NICE

        let total = userDelta + systemDelta + idleDelta + niceDelta
        guard total > 0 else { return 0.0 }

        let used = userDelta + systemDelta + niceDelta
        let usage = (used / total) * 100.0

        // Clamp to [0, 100] to guard against any transient tick overflow.
        return max(0.0, min(100.0, usage))
    }
}
