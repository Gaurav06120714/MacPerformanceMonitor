import Foundation
import Combine

/// Aggregates all hardware monitors and publishes live stats to the UI.
///
/// Runs on the main queue — each monitor call takes only microseconds,
/// so there is no perceptible jank from calling them on main at 1-second
/// intervals. This avoids @MainActor + background-GCD isolation conflicts
/// that would silently suppress @Published updates.
@MainActor
final class SystemMonitor: ObservableObject {

    // MARK: - Published stats

    @Published var cpuUsage: Double = 0
    @Published var ramUsage: Double = 0          // percentage 0-100
    @Published var ramUsedGB: Double = 0          // e.g. 9.3
    @Published var ramTotalGB: Double = 0         // e.g. 16.0
    @Published var gpuUsage: Double? = nil
    @Published var fps: Double = 0
    @Published var netUpMBps: Double = 0
    @Published var netDownMBps: Double = 0

    @Published var cpuHistory: [Double] = []
    @Published var ramHistory: [Double] = []
    @Published var topProcesses: [ProcessInfo2] = []
    @Published var uptime: TimeInterval = 0

    // MARK: - Configuration

    var refreshInterval: Double = AppPreferences.shared.refreshInterval {
        didSet {
            guard refreshInterval != oldValue else { return }
            restartTimer()
        }
    }

    // MARK: - Private

    private let cpuMonitor  = CPUMonitor()
    private let ramMonitor  = RAMMonitor()
    private let gpuMonitor  = GPUMonitor()
    private let fpsMonitor  = FPSMonitor()
    private let netMonitor  = NetworkMonitor()

    private var timer: Timer?
    private var tickCount: Int = 0          // increments each sample
    private let startDate = Date()

    // MARK: - Lifecycle

    init() {}

    /// Begin sampling. Call once from the app delegate.
    func start() {
        // Warm up CPU monitor — first call always returns 0 (no previous sample).
        // By priming it here, the second call (first timer fire) returns real data.
        _ = cpuMonitor.cpuUsage()

        fpsMonitor.start()
        startTimer()
        appLogger.info("SystemMonitor started (interval: \(self.refreshInterval)s)")
    }

    /// Stop all sampling. Call on app termination.
    func stop() {
        stopTimer()
        fpsMonitor.stop()
        appLogger.info("SystemMonitor stopped")
    }

    // MARK: - Timer management

    private func startTimer() {
        // Run on main RunLoop — all @Published mutations stay on main actor,
        // no cross-queue coordination needed.
        timer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { [weak self] _ in
            // Timer fires on main thread; hop to MainActor to satisfy isolation.
            guard let self else { return }
            Task { @MainActor in self.sample() }
        }
        // Keep firing even during event tracking (e.g. menu open).
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        stopTimer()
        startTimer()
    }

    // MARK: - Sampling (main thread)

    private func sample() {
        let cpu      = cpuMonitor.cpuUsage()
        let ram      = ramMonitor.ramUsage()
        let ramBytes = ramMonitor.ramBytesUsedAndTotal()
        let gpu      = gpuMonitor.gpuUsage()
        let vsync    = fpsMonitor.fps
        let net      = netMonitor.throughput()

        cpuUsage    = cpu
        ramUsage    = ram
        ramUsedGB   = Double(ramBytes.used)  / 1_073_741_824.0
        ramTotalGB  = Double(ramBytes.total) / 1_073_741_824.0
        gpuUsage    = gpu
        fps         = vsync
        netUpMBps   = net.uploadMBps
        netDownMBps = net.downloadMBps
        uptime      = Date().timeIntervalSince(startDate)
        tickCount  += 1

        // Rolling 60-point histories for sparklines.
        cpuHistory.append(cpu)
        if cpuHistory.count > 60 { cpuHistory.removeFirst() }

        ramHistory.append(ram)
        if ramHistory.count > 60 { ramHistory.removeFirst() }

        // Refresh top processes every 5 seconds — ps is heavy for a 1s loop.
        if tickCount % 5 == 1 {
            Task.detached(priority: .utility) {
                let procs = await Self.fetchTopProcesses()
                await MainActor.run { [weak self] in self?.topProcesses = procs }
            }
        }
    }

    // MARK: - Top processes

    /// Run `ps` and parse the top 5 CPU-using processes. Called off-main.
    static func fetchTopProcesses() async -> [ProcessInfo2] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let task = Process()
                task.launchPath = "/bin/ps"
                task.arguments = ["-Ao", "pid,pcpu,comm", "-r"]

                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError  = Pipe()

                do {
                    try task.run()
                } catch {
                    monitorLogger.error("ps failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                task.waitUntilExit()

                let data   = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8) else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [ProcessInfo2] = []
                let lines = output.components(separatedBy: "\n").dropFirst()

                for line in lines {
                    let parts = line.trimmingCharacters(in: .whitespaces)
                                    .components(separatedBy: .whitespaces)
                    guard parts.count >= 3,
                          let pid = Int(parts[0]),
                          let cpu = Double(parts[1])
                    else { continue }

                    let rawName = parts[2...].joined(separator: " ")
                    let name    = URL(fileURLWithPath: rawName).lastPathComponent

                    results.append(ProcessInfo2(pid: pid, name: name, cpuPercent: cpu))
                    if results.count >= 5 { break }
                }

                continuation.resume(returning: results)
            }
        }
    }

    // MARK: - Preview helper

    static func preview() -> SystemMonitor {
        let m = SystemMonitor()
        m.cpuUsage = 34
        m.ramUsage = 58
        m.gpuUsage = 42
        m.fps      = 120
        m.cpuHistory = (0..<60).map { _ in Double.random(in: 20...60) }
        m.ramHistory = (0..<60).map { _ in Double.random(in: 50...70) }
        return m
    }
}

// MARK: - Supporting types

struct ProcessInfo2: Identifiable {
    let id = UUID()
    let pid: Int
    let name: String
    let cpuPercent: Double
}
