import Foundation
import Darwin

/// Measures real-time network throughput by diffing interface byte counters.
/// Uses getifaddrs to read per-interface TX/RX bytes, then computes MB/s delta.
final class NetworkMonitor {

    private var previousBytes: (up: UInt64, down: UInt64) = (0, 0)
    private var previousTime: Double = 0

    init() {
        // Prime the baseline so first call returns real delta not a spike
        previousBytes = totalBytes()
        previousTime  = currentTime()
    }

    struct Throughput {
        let uploadMBps:   Double   // megabytes per second sent
        let downloadMBps: Double   // megabytes per second received
    }

    /// Returns upload/download in MB/s since last call. Call at your sample interval.
    func throughput() -> Throughput {
        let now   = currentTime()
        let bytes = totalBytes()
        let dt    = now - previousTime

        guard dt > 0.01 else { return Throughput(uploadMBps: 0, downloadMBps: 0) }

        let upDelta   = bytes.up   > previousBytes.up   ? bytes.up   - previousBytes.up   : 0
        let downDelta = bytes.down > previousBytes.down ? bytes.down - previousBytes.down : 0

        previousBytes = bytes
        previousTime  = now

        let upMBps   = Double(upDelta)   / dt / 1_048_576.0
        let downMBps = Double(downDelta) / dt / 1_048_576.0

        return Throughput(
            uploadMBps:   min(upMBps,   9999),
            downloadMBps: min(downMBps, 9999)
        )
    }

    // MARK: - Private

    /// Sum TX/RX bytes across all active non-loopback interfaces via getifaddrs.
    private func totalBytes() -> (up: UInt64, down: UInt64) {
        var totalUp:   UInt64 = 0
        var totalDown: UInt64 = 0

        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let ifList = ifap else { return (0, 0) }
        defer { freeifaddrs(ifList) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = ifList
        while let ifa = cursor {
            defer { cursor = ifa.pointee.ifa_next }

            // Only AF_LINK entries carry the if_data byte counters
            guard ifa.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK) else { continue }

            // Skip loopback
            let name = String(cString: ifa.pointee.ifa_name)
            guard !name.hasPrefix("lo") else { continue }

            if let data = ifa.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                totalUp   += UInt64(data.pointee.ifi_obytes)
                totalDown += UInt64(data.pointee.ifi_ibytes)
            }
        }

        return (totalUp, totalDown)
    }

    private func currentTime() -> Double {
        Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000.0
    }
}
