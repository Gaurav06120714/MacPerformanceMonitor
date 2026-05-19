import SwiftUI

/// The SwiftUI view shown inside the NSPopover when the user clicks the menu bar item.
///
/// Sections:
///   1. Live Stats      — large numeric display for each metric
///   2. Mini Graphs     — 60-point sparklines for CPU and RAM
///   3. Top Processes   — top 5 by CPU via `ps`
///   4. Controls        — refresh interval, launch at login, quit
///   5. Footer          — version and uptime
struct DropdownView: View {

    @ObservedObject var monitor: SystemMonitor

    // Settings state, kept in sync with AppPreferences via @AppStorage.
    @AppStorage("refreshInterval") private var refreshInterval: Double = 1.0
    @AppStorage("showGPU")         private var showGPU: Bool    = true
    @AppStorage("showFPS")         private var showFPS: Bool    = true

    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var showSettings: Bool  = false

    var body: some View {
        if showSettings {
            SettingsView(monitor: monitor, onBack: { showSettings = false })
        } else {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                liveStatsSection
                Divider().padding(.vertical, 6)
                miniGraphsSection
                Divider().padding(.vertical, 6)
                topProcessesSection
                Divider().padding(.vertical, 6)
                controlsSection
                Divider().padding(.vertical, 6)
                footerSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 280)
        .background(.regularMaterial)
        } // end else
        
    }

    // MARK: - Live Stats

    private var liveStatsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Stats")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                statCard(label: "CPU", value: monitor.cpuUsage,
                         valueStr: String(format: "%.0f%%", monitor.cpuUsage),
                         color: metricColor(monitor.cpuUsage))

                statCard(label: "RAM", value: monitor.ramUsage,
                         valueStr: String(format: "%.0f%%", monitor.ramUsage),
                         color: metricColor(monitor.ramUsage))

                if showGPU, let gpu = monitor.gpuUsage {
                    statCard(label: "GPU", value: gpu,
                             valueStr: String(format: "%.0f%%", gpu),
                             color: metricColor(gpu))
                }

                if showFPS {
                    statCard(label: "VSYNC", value: nil,
                             valueStr: String(format: "%.0f Hz", monitor.fps),
                             color: .primary)
                }
            }
        }
    }

    private func statCard(label: String, value: Double?, valueStr: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(valueStr)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Mini Graphs

    private var miniGraphsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History (60s)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CPU").font(.system(size: 9)).foregroundStyle(.secondary)
                    MiniGraphView(data: monitor.cpuHistory, color: metricColor(monitor.cpuUsage))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("RAM").font(.system(size: 9)).foregroundStyle(.secondary)
                    MiniGraphView(data: monitor.ramHistory, color: metricColor(monitor.ramUsage))
                }
            }
        }
    }

    // MARK: - Top Processes

    private var topProcessesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Top Processes")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            if monitor.topProcesses.isEmpty {
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(monitor.topProcesses) { proc in
                    HStack {
                        Text(proc.name)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1f%%", proc.cpuPercent))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(metricColor(proc.cpuPercent))
                    }
                }
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Controls")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            // Refresh interval
            HStack {
                Text("Refresh")
                    .font(.system(size: 11))
                Spacer()
                Picker("", selection: $refreshInterval) {
                    Text("0.5s").tag(0.5)
                    Text("1s").tag(1.0)
                    Text("2s").tag(2.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                .onChange(of: refreshInterval) { newValue in
                    AppPreferences.shared.refreshInterval = newValue
                    monitor.refreshInterval = newValue
                }
            }

            // Launch at login
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .font(.system(size: 11))
                .onChange(of: launchAtLogin) { newValue in
                    LaunchAtLogin.isEnabled = newValue
                }

            HStack(spacing: 8) {
                Button("Settings…") {
                    showSettings = true
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("v\(appVersion)")
            Spacer()
            Text("Up \(uptimeString)")
        }
        .font(.system(size: 9))
        .foregroundStyle(.tertiary)
    }

    // MARK: - Helpers

    private func metricColor(_ value: Double) -> Color {
        switch value {
        case ..<50:  return .green
        case ..<80:  return .yellow
        default:     return .red
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var uptimeString: String {
        let t = Int(monitor.uptime)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }
}
