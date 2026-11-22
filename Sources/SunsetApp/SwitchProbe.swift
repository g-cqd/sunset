import Foundation
import SunsetPane
import SunsetRuntime
import SunsetShell

/// A harness for the cost of switching tabs, off unless `SUNSET_PROBE_SWITCH` names a file: a few seconds after the window
/// opened it selects every tab in turn, three rounds, and writes one line per switch to that file: the tab's index, the time
/// `select(item:)` took, and the time until the main run loop was next idle (the layout, the SwiftUI update and the commit
/// that the switch caused), in milliseconds.
@MainActor
enum SwitchProbe {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    static var runtime = Runtime.live

    private static var started = false

    static func startIfAsked(_ tabs: TabsModel) {
        guard !started, let path = ProcessInfo.processInfo.environment["SUNSET_PROBE_SWITCH"] else { return }
        started = true
        runtime.task {
            await runtime.sleep(
                for: .seconds(Double(ProcessInfo.processInfo.environment["SUNSET_PROBE_WAIT"] ?? "") ?? 8)
            )
            var lines: [String] = []
            for round in 0 ..< 3 {
                for (index, item) in tabs.workspace.items.enumerated() {
                    let begin = runtime.uptime()
                    tabs.select(item: item.id)
                    let selected = runtime.uptime()
                    await idle()
                    let settled = runtime.uptime()
                    lines.append("\(round) \(index) \(milliseconds(selected - begin)) \(milliseconds(settled - begin))")
                    // `SUNSET_PROBE_GAP` (ms): longer than a second, each switch is followed by its session save.
                    await runtime.sleep(
                        for: .milliseconds(Int(ProcessInfo.processInfo.environment["SUNSET_PROBE_GAP"] ?? "") ?? 250)
                    )
                }
            }
            try? lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    private static func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15
    }

    /// Returns when the main run loop is about to wait: after every observer (SwiftUI's update, Core Animation's commit) has run.
    private static func idle() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let observer = CFRunLoopObserverCreateWithHandler(
                nil,
                CFRunLoopActivity.beforeWaiting.rawValue,
                false,
                CFIndex.max
            ) { _, _ in continuation.resume() }
            CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
    }
}
