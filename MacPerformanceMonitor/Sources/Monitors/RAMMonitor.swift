import Darwin
import Foundation

/// Reads physical memory utilisation via `host_statistics64(HOST_VM_INFO64)`.
///
/// Memory categories (following Activity Monitor's definitions):
///   App Memory  = active_count
///   Wired       = wire_count
///   Compressed  = compressor_page_count
///   Used        = (active + wired + compressor) * page_size
///   Total       = ProcessInfo.processInfo.physicalMemory
final class RAMMonitor {

    private let pageSize: UInt64

    init() {
        pageSize = UInt64(vm_kernel_page_size)
    }

    // MARK: - Public API

    /// Returns current RAM utilisation as a percentage in the range 0–100.
    func ramUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let kr: kern_return_t = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPtr, &count)
            }
        }

        guard kr == KERN_SUCCESS else {
            monitorLogger.error("host_statistics64(HOST_VM_INFO64) failed: \(kr)")
            return 0.0
        }

        // Pages in active use (recently accessed).
        let active    = UInt64(stats.active_count)
        // Pages locked in memory by the kernel or drivers.
        let wired     = UInt64(stats.wire_count)
        // Pages held by the memory compressor (counts as "used").
        let compressor = UInt64(stats.compressor_page_count)

        let usedBytes  = (active + wired + compressor) * pageSize
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        guard totalBytes > 0 else { return 0.0 }

        let usage = Double(usedBytes) / Double(totalBytes) * 100.0
        return max(0.0, min(100.0, usage))
    }

    /// Returns used and total RAM in bytes, for display in the dropdown.
    func ramBytesUsedAndTotal() -> (used: UInt64, total: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let kr: kern_return_t = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPtr, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return (0, 0) }

        let active    = UInt64(stats.active_count)
        let wired     = UInt64(stats.wire_count)
        let compressor = UInt64(stats.compressor_page_count)
        let usedBytes  = (active + wired + compressor) * pageSize
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        return (usedBytes, totalBytes)
    }

    // MARK: - Formatting helpers

    /// Format bytes as a human-readable GB string, e.g. "12.3 GB".
    static func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576.0
        return String(format: "%.0f MB", mb)
    }
}
