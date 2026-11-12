import CoreGraphics
import Foundation

/// A picture of one of the app's windows (`screencapture -l`), which works while the window is behind others.
enum Capture {
    static func windows(pid: pid_t) -> [(id: Int, title: String, bounds: CGRect)] {
        let list = (CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]) ?? []
        return list.compactMap { info in
            guard (info[kCGWindowOwnerPID as String] as? Int32) == pid, (info[kCGWindowLayer as String] as? Int) == 0,
                let id = info[kCGWindowNumber as String] as? Int,
                let bounds = info[kCGWindowBounds as String] as? [String: Double]
            else { return nil }
            let frame = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )
            guard frame.width > 50, frame.height > 50 else { return nil }
            return (id, info[kCGWindowName as String] as? String ?? "", frame)
        }
    }

    static func shot(pid: pid_t, to path: String, window: String?) -> Bool {
        let all = windows(pid: pid)
        // Named: the first whose title holds it; else the largest (helper windows are small or blank).
        let largest = all.max { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }
        let named = window.flatMap { name in all.first { $0.title.lowercased().contains(name.lowercased()) } }
        guard let target = named ?? largest else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", "-o", "-l", String(target.id), path]
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
