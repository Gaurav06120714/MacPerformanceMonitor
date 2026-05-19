import SwiftUI

struct SettingsView: View {

    @ObservedObject var monitor: SystemMonitor
    var onBack: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @AppStorage("refreshInterval") private var refreshInterval: Double = 0.5
    @AppStorage("showGPU")         private var showGPU: Bool    = true
    @AppStorage("showFPS")         private var showFPS: Bool    = true
    @AppStorage("showRAM")         private var showRAM: Bool    = true
    @AppStorage("showCPU")         private var showCPU: Bool    = true
    @AppStorage("showPercentSign") private var showPercentSign: Bool = true
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack {
                Button(action: { onBack?() ?? dismiss() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Settings")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Color.clear.frame(width: 44)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            // Refresh Rate
            settingRow {
                Text("Refresh Rate")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            settingRow {
                Text("Update interval")
                    .font(.system(size: 12))
                Spacer()
                Picker("", selection: $refreshInterval) {
                    Text("0.5s").tag(0.5)
                    Text("1s").tag(1.0)
                    Text("2s").tag(2.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                .onChange(of: refreshInterval) { v in
                    AppPreferences.shared.refreshInterval = v
                    monitor.refreshInterval = v
                }
            }

            Divider().padding(.vertical, 4)

            // Menu Bar Display
            settingRow {
                Text("Menu Bar Display")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            compactToggle("Show CPU",      isOn: $showCPU)
            compactToggle("Show RAM",      isOn: $showRAM)
            compactToggle("Show GPU",      isOn: $showGPU)
            compactToggle("Show Hz",       isOn: $showFPS)
            compactToggle("Show % symbol", isOn: $showPercentSign)

            Divider().padding(.vertical, 4)

            // System
            settingRow {
                Text("System")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            compactToggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { v in LaunchAtLogin.isEnabled = v }

            Spacer(minLength: 0)
        }
        .frame(width: 340, height: 320)
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingRow<C: View>(@ViewBuilder content: () -> C) -> some View {
        HStack { content() }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
    }

    @ViewBuilder
    private func compactToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.system(size: 12))
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().toggleStyle(.switch)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 3)
    }
}
