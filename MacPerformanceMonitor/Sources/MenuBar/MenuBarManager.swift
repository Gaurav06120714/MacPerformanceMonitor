import AppKit
import SwiftUI

@MainActor
final class MenuBarManager: NSObject {

    private let monitor: SystemMonitor
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var timer: Timer?
    private var lastTitle: String = ""

    init(monitor: SystemMonitor) {
        self.monitor = monitor
        super.init()
    }

    func setup() {
        createStatusItem()
        createPopover()
        startTitleTimer()
    }

    // MARK: - Status item

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
    }

    private func createPopover() {
        let p = NSPopover()
        p.contentSize = CGSize(width: 300, height: 480)
        p.behavior = .transient
        p.animates = false
        p.contentViewController = NSHostingController(rootView: DropdownView(monitor: monitor))
        popover = p
    }

    // MARK: - Timer

    private func startTitleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateTitle() }
        }
        RunLoop.main.add(timer!, forMode: .common)
        Task { @MainActor in self.updateTitle() }
    }

    private func updateTitle() {
        guard let button = statusItem?.button else { return }

        let cpu      = monitor.cpuUsage
        let ramGB    = monitor.ramUsedGB
        let gpu      = monitor.gpuUsage
        let fps      = monitor.fps
        let upMBps   = monitor.netUpMBps
        let downMBps = monitor.netDownMBps

        // Cache check — skip redraw if nothing changed
        let key = "\(Int(cpu))-\(String(format:"%.1f",ramGB))-\(gpu.map{"\(Int($0))"} ?? "x")-\(Int(fps))-\(Int(upMBps*10))-\(Int(downMBps*10))"
        guard key != lastTitle else { return }
        lastTitle = key

        button.attributedTitle = buildTitle(
            cpu: cpu, ramGB: ramGB, gpu: gpu,
            fps: fps, upMBps: upMBps, downMBps: downMBps
        )
    }

    // MARK: - Attributed title builder

    private func buildTitle(
        cpu: Double,
        ramGB: Double,
        gpu: Double?,
        fps: Double,
        upMBps: Double,
        downMBps: Double
    ) -> NSAttributedString {

        let valFont   = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .semibold)
        let labelFont = NSFont.monospacedSystemFont(ofSize: 10.0, weight: .regular)
        let out       = NSMutableAttributedString()

        func pctColor(_ v: Double) -> NSColor {
            v < 50 ? .systemGreen : v < 80 ? .systemYellow : .systemRed
        }

        func label(_ s: String) {
            out.append(NSAttributedString(string: s, attributes: [
                .font: labelFont, .foregroundColor: NSColor.labelColor
            ]))
        }

        func value(_ s: String, _ color: NSColor) {
            out.append(NSAttributedString(string: s, attributes: [
                .font: valFont, .foregroundColor: color
            ]))
        }

        func gap() {
            out.append(NSAttributedString(string: "  ", attributes: [
                .font: labelFont, .foregroundColor: NSColor.tertiaryLabelColor
            ]))
        }

        // CPU — %
        label("CPU "); value("\(Int(cpu))%", pctColor(cpu))

        // RAM — actual GB (e.g. 9.3G)
        gap(); label("RAM ")
        let ramStr = ramGB < 10 ? String(format: "%.1fG", ramGB) : String(format: "%.0fG", ramGB)
        value(ramStr, .systemGreen)

        // GPU — % if available
        if let gpu {
            gap(); label("GPU "); value("\(Int(gpu))%", pctColor(gpu))
        }

        // Hz — display refresh rate, always cyan
        gap(); label("Hz "); value("\(Int(fps))", .systemCyan)

        // Network — always visible, shows 0K when idle
        gap()
        out.append(NSAttributedString(string: "↑", attributes: [.font: labelFont, .foregroundColor: NSColor.systemTeal]))
        value(speedStr(upMBps), .systemTeal)
        out.append(NSAttributedString(string: " ↓", attributes: [.font: labelFont, .foregroundColor: NSColor.systemBlue]))
        value(speedStr(downMBps), .systemBlue)

        return out
    }

    /// "1.2M" for ≥1 MB/s, "345K" for KB/s
    private func speedStr(_ mbps: Double) -> String {
        mbps >= 1.0
            ? String(format: "%.1fM", mbps)
            : String(format: "%.0fK", mbps * 1024)
    }

    // MARK: - Popover

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func teardown() {
        timer?.invalidate()
        timer = nil
        popover?.close()
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
    }
}
