import SwiftUI

/// Full settings panel, shown as a separate window (not the popover).
/// Currently exposed via the "Settings…" button in the dropdown.
struct SettingsView: View {

    @ObservedObject var monitor: SystemMonitor

    @AppStorage("refreshInterval") private var refreshInterval: Double = 1.0
    @AppStorage("showGPU")         private var showGPU: Bool    = true
    @AppStorage("showFPS")         private var showFPS: Bool    = true
    @AppStorage("showRAM")         private var showRAM: Bool    = true
    @AppStorage("showCPU")         private var showCPU: Bool    = true
    @AppStorage("showPercentSign") private var showPercentSign: Bool = true

    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section("Refresh Rate") {
                Picker("Update interval", selection: $refreshInterval) {
                    Text("0.5 s").tag(0.5)
                    Text("1 s").tag(1.0)
                    Text("2 s").tag(2.0)
                }
                .pickerStyle(.segmented)
                .onChange(of: refreshInterval) { newValue in
                    AppPreferences.shared.refreshInterval = newValue
                    monitor.refreshInterval = newValue
                }
            }

            Section("Menu Bar Display") {
                Toggle("Show CPU", isOn: $showCPU)
                Toggle("Show RAM", isOn: $showRAM)
                Toggle("Show GPU", isOn: $showGPU)
                Toggle("Show Display VSYNC (FPS)", isOn: $showFPS)
                Toggle("Show percent symbol (%)", isOn: $showPercentSign)
            }

            Section("System") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.isEnabled = newValue
                    }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: appBuild)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 420)
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
