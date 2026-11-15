import Foundation

/// Whether FileVault protects the disk (R12 step ST-6): the only protection of what Sunset does not seal (the website data).
/// The Mac is asked with `fdesetup isactive`, which answers anyone; the volume's "encrypted" flag does not say (it is false on
/// a Mac whose disk FileVault protects: diary 2026-11-15-01).
public enum FileVaultState: Sendable, Equatable {
    case on, off, unknown

    /// - Parameter answer: what `fdesetup isactive` printed.
    init(answer: String) {
        switch answer.trimmingCharacters(in: .whitespacesAndNewlines) {
            case "true": self = .on
            case "false": self = .off
            default: self = .unknown
        }
    }

    /// Asks the Mac. `.unknown` when the tool is not there or says something else.
    public static func read(tool: String = "/usr/bin/fdesetup") async -> FileVaultState {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = ["isactive"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        return await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                let data = (try? output.fileHandleForReading.readToEnd()) ?? Data()
                continuation.resume(returning: FileVaultState(answer: String(decoding: data, as: UTF8.self)))
            }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(returning: .unknown)
            }
        }
    }
}
