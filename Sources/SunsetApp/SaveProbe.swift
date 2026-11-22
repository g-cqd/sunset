import Foundation

/// A harness for the main thread's share of a session save, off unless `SUNSET_PROBE_SAVE` names a file: one line per
/// save, whether it went to the background, and the milliseconds the main thread spent on it.
@MainActor
enum SaveProbe {
    private static let path = ProcessInfo.processInfo.environment["SUNSET_PROBE_SAVE"]
    /// `SUNSET_PROBE_SAVE_HERE`: every save on the main thread, as before, to compare.
    static let writesHere = ProcessInfo.processInfo.environment["SUNSET_PROBE_SAVE_HERE"] != nil

    static func record(_ spent: Duration, inBackground: Bool) {
        guard let path else { return }
        let milliseconds = Double(spent.components.seconds) * 1000 + Double(spent.components.attoseconds) / 1e15
        let line = "\(inBackground ? "background" : "here") \(milliseconds)\n"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? line.write(toFile: path, atomically: false, encoding: .utf8)
        }
    }
}
