import Darwin
import Foundation

/// Starts a test Sunset (`launch`): a fresh folder under /tmp/axdrive with the configuration and session given (or none), the app in the
/// background (`SUNSET_BACKGROUND=1`) marked as a test (`AXDRIVE_TEST=1`); returns once a window of it exists, not after a fixed wait.
enum Launcher {
    /// A fresh folder with the configuration and the session given.
    private static func prepare(_ folder: String, _ options: Options) {
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
    }

    static func launch(_ options: Options) async -> Int32 {
        // `--again FOLDER`: a second run on the folder of an earlier one, as it was left (what a relaunch restores).
        let again = options.values["again"].flatMap { $0.hasPrefix(Guard.root) ? $0 : nil }
        let folder = again ?? Guard.root + "\(Int(Date().timeIntervalSince1970 * 1000))"
        if again == nil { prepare(folder, options) }
        let binary = options.values["binary"] ?? ".build/out/Products/Debug/sunset-app"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        var environment = ProcessInfo.processInfo.environment
        environment["SUNSET_CONFIG"] = folder + "/config.json"
        environment["SUNSET_BACKGROUND"] = "1"
        environment["AXDRIVE_TEST"] = "1"
        process.environment = environment
        if let file = options.values["open"] { return await open(file, bundleOf: binary, folder: folder, options) }
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

    /// `--open FILE`: the app is started by opening a file with it, as Finder's Open With does. Through Launch Services, as a
    /// new instance (`open -n`), so the file cannot be handed to another Sunset that is running, and in the background.
    private static func open(_ file: String, bundleOf binary: String, folder: String, _ options: Options) async -> Int32
    {
        let bundle = URL(fileURLWithPath: binary).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().path
        let config = folder + "/config.json"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-n", "-g", "-a", bundle, "--env", "SUNSET_CONFIG=" + config, "--env", "SUNSET_BACKGROUND=1", "--env",
            "AXDRIVE_TEST=1", file
        ]
        do { try process.run() } catch { return Commands.fail("could not run open: \(error)") }
        process.waitUntilExit()
        let deadline = Date().addingTimeInterval(options.double("timeout", 20))
        while Date() < deadline {
            for pid in pids(running: binary) where Guard.environment(of: pid)?["SUNSET_CONFIG"] == config {
                guard !Capture.windows(pid: pid).isEmpty else { continue }
                print(pid, folder)
                return 0
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return Commands.fail("no window within the timeout")
    }

    /// The processes whose executable is `binary`.
    private static func pids(running binary: String) -> [pid_t] {
        let wanted = URL(fileURLWithPath: binary).resolvingSymlinksInPath().path
        var all = [pid_t](repeating: 0, count: 4096)
        let bytes = proc_listallpids(&all, Int32(all.count * MemoryLayout<pid_t>.size))
        return all.prefix(max(0, Int(bytes)))
            .filter { pid in
                var path = [CChar](repeating: 0, count: 4096)
                guard pid > 0, proc_pidpath(pid, &path, UInt32(path.count)) > 0 else { return false }
                let text = String(decoding: path.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
                return URL(fileURLWithPath: text).resolvingSymlinksInPath().path == wanted
            }
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
