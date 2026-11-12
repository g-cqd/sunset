import Darwin
import Foundation

/// axdrive acts only on what it can prove is a test (the owner, 2026-11-12: no trouble, ever, on data that is not a dummy): a process it launched
/// itself, carrying `AXDRIVE_TEST=1` and a `SUNSET_CONFIG` inside axdrive's own folder under /tmp. Anything else, the owner's Sunset, another app,
/// a process whose environment cannot be read, is refused, reading included.
enum Guard {
    static let root = "/tmp/axdrive/"

    static func allows(_ pid: pid_t) -> Bool {
        guard pid > 0, let environment = environment(of: pid) else { return false }
        guard environment["AXDRIVE_TEST"] == "1", let config = environment["SUNSET_CONFIG"] else { return false }
        let resolved = URL(fileURLWithPath: config).resolvingSymlinksInPath().path
        return resolved.hasPrefix(root) || resolved.hasPrefix("/private" + root)
    }

    /// The environment a process was started with, from the kernel (`KERN_PROCARGS2`); nil when it cannot be read.
    static func environment(of pid: pid_t) -> [String: String]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return nil }
        let argc = buffer.withUnsafeBytes { $0.load(as: Int32.self) }
        // After argc: the executable's path, padding NULs, argc arguments, then the environment, each NUL-terminated.
        let strings = buffer[MemoryLayout<Int32>.size ..< size].split(separator: 0, omittingEmptySubsequences: true)
            .map { String(decoding: $0, as: UTF8.self) }
        guard strings.count > Int(argc) + 1 else { return [:] }
        var result: [String: String] = [:]
        for entry in strings.dropFirst(Int(argc) + 1) {
            guard let equal = entry.firstIndex(of: "=") else { continue }
            result[String(entry[..<equal])] = String(entry[entry.index(after: equal)...])
        }
        return result
    }
}
