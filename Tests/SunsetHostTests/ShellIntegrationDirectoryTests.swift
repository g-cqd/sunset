import Foundation
import SunsetCore
import Testing

@testable import SunsetHost

/// The directory a taught shell reports (OSC 7, T-2 / t186) is the exact directory it is in, whatever the name holds:
/// accents and other scripts (percent-encoded as UTF-8 bytes, which is what OSC 7 carries and Sunset decodes), spaces,
/// `%`, `#` and `?`. Checked with the real shells, in a UTF-8 locale as a Mac's Terminal has, by the path Sunset decoded —
/// not by whether a report arrived.
@Suite("Shell integration: reported directory", .serialized) struct ShellIntegrationDirectoryTests {
    static let shells: [String] = ["/bin/zsh", "/bin/bash", "/opt/homebrew/bin/bash"]
        .filter { FileManager.default.isExecutableFile(atPath: $0) }

    @Test(arguments: shells)
    func `the reported directory is the one the shell is in, byte for byte`(shell: String) throws {
        let base = NSTemporaryDirectory() + "sunset-osc7-\(UUID().uuidString)"
        let home = base + "/home"
        let target = base + "/Café 日本 100% #1?"
        for path in [home, target] {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
        defer { try? FileManager.default.removeItem(atPath: base) }

        let inherited = ["HOME": home, "TERM": "xterm-256color", "LANG": "en_US.UTF-8", "LC_ALL": "en_US.UTF-8"]
        let prepared = try ShellIntegration.prepare(
            command: [shell, "-i"],
            inherited: inherited,
            directory: base + "/int"
        )
        let environment = inherited.merging(prepared.environment) { _, added in added }
        let session = try HeadlessSession(prepared.command, columns: 200, rows: 10, environment: environment)
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } }, "\(shell) never prompted")
        try session.send("cd '\(target)'\n")
        let reached = session.wait { $0.screen.workingDirectory?.path == target }
        #expect(reached, "\(shell) reported \(String(describing: session.terminal.screen.workingDirectory?.path))")
        try session.send("exit\n")
        #expect(session.waitForExit())
    }
}
