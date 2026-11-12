import Foundation

/// Starts a test Sunset (`launch`): a fresh folder under /tmp/axdrive with the configuration and session given (or none), the app in the
/// background (`SUNSET_BACKGROUND=1`) marked as a test (`AXDRIVE_TEST=1`); returns once a window of it exists, not after a fixed wait.
enum Launcher {
    static func launch(_ options: Options) async -> Int32 {
        let folder = Guard.root + "\(Int(Date().timeIntervalSince1970 * 1000))"
        let manager = FileManager.default
        try? manager.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let config = options.values["config"] ?? "{}"
        try? Data(
            (config.hasPrefix("{") ? config : (try? String(contentsOfFile: config, encoding: .utf8)) ?? "{}").utf8
        )
        .write(to: URL(fileURLWithPath: folder + "/config.json"))
        if let session = options.values["session"] {
            try? manager.copyItem(atPath: session, toPath: folder + "/session.json")
        }
        let binary = options.values["binary"] ?? ".build/out/Products/Debug/sunset-app"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        var environment = ProcessInfo.processInfo.environment
        environment["SUNSET_CONFIG"] = folder + "/config.json"
        environment["SUNSET_BACKGROUND"] = "1"
        environment["AXDRIVE_TEST"] = "1"
        process.environment = environment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle(forWritingAtPath: "/dev/null")
        do { try process.run() } catch { return Commands.fail("could not start \(binary): \(error)") }
        let deadline = Date().addingTimeInterval(options.double("timeout", 20))
        while Date() < deadline {
            if !Capture.windows(pid: process.processIdentifier).isEmpty {
                print(process.processIdentifier, folder)
                return 0
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        process.terminate()
        return Commands.fail("no window within the timeout")
    }

    /// Ends a test copy (only one the guard allows).
    static func stop(_ pid: pid_t) -> Int32 {
        guard Guard.allows(pid) else { return refused(pid) }
        kill(pid, SIGTERM)
        return 0
    }

    static func refused(_ pid: pid_t) -> Int32 {
        FileHandle.standardError.write(Data("axdrive: refused: \(pid) is not a test copy launched by axdrive\n".utf8))
        return 4
    }
}
