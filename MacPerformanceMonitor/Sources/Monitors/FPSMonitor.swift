import CoreVideo
import Foundation

// MARK: - Display Hz Monitor
//
// What this measures:
//   The display's active refresh rate via CVDisplayLink VSYNC callbacks.
//   On a 60 Hz display this returns ~60. On 120 Hz ProMotion it returns ~120.
//   It drops when macOS lowers refresh rate to save power (e.g. 48 Hz idle).
//
// Why game FPS is impossible from outside a process on macOS:
//   Metal's MTLDrawable.presentedTime and CAMetalLayer frame counters are only
//   readable from inside the rendering process. macOS has no global DXGI-style
//   present queue (unlike Windows). An external app cannot hook into another
//   process's GPU command queue without disabling SIP.
//
// What we show: Display Hz — the ceiling FPS any app on this display can hit.
// Label it "Hz" in the UI, not "FPS", to be accurate.

final class FPSMonitor {

    private var displayLink: CVDisplayLink?
    private var frameCount: Int = 0
    private var windowStart: UInt64 = 0
    private var timebase = mach_timebase_info_data_t()

    private let lock = NSLock()
    private var _hz: Double = 0.0

    /// Current display refresh rate in Hz. Thread-safe.
    var fps: Double {
        lock.withLock { _hz }
    }

    init() {
        mach_timebase_info(&timebase)
    }

    deinit { stop() }

    func start() {
        guard displayLink == nil else { return }

        var link: CVDisplayLink?
        guard CVDisplayLinkCreateWithActiveCGDisplays(&link) == kCVReturnSuccess,
              let link else {
            monitorLogger.error("CVDisplayLinkCreateWithActiveCGDisplays failed")
            return
        }

        displayLink = link
        windowStart = mach_absolute_time()
        frameCount  = 0

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(link, { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo else { return kCVReturnSuccess }
            Unmanaged<FPSMonitor>.fromOpaque(userInfo).takeUnretainedValue().tick()
            return kCVReturnSuccess
        }, selfPtr)

        CVDisplayLinkStart(link)
        monitorLogger.info("FPSMonitor started")
    }

    func stop() {
        if let link = displayLink { CVDisplayLinkStop(link) }
        displayLink = nil
    }

    private func tick() {
        frameCount += 1
        let now = mach_absolute_time()
        let ns  = (now - windowStart) * UInt64(timebase.numer) / UInt64(timebase.denom)
        let sec = Double(ns) / 1_000_000_000.0

        if sec >= 1.0 {
            let hz = Double(frameCount) / sec
            lock.withLock { _hz = hz }
            frameCount  = 0
            windowStart = now
        }
    }
}
