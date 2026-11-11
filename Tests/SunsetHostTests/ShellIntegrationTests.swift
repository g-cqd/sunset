import Foundation
import SunsetCore
import Testing

@testable import SunsetHost

/// The shell is taught to mark its prompts (OSC 133) without the user's files being touched.
@Suite("Shell integration", .serialized) struct ShellIntegrationTests {
    private func temporary(_ name: String) throws -> String {
        let path = NSTemporaryDirectory() + "sunset-shell-\(name)-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }

    @Test func `only zsh is taught, by a directory of its own that hands the user's back`() throws {
        let directory = try temporary("plain")
        let none = try ShellIntegration.environment(
            for: ["/bin/sh", "-c", "true"],
            inherited: [:],
            directory: directory
        )
        #expect(none.isEmpty)
        let plain = try ShellIntegration.environment(for: ["/bin/zsh", "-l"], inherited: [:], directory: directory)
        #expect(plain == ["ZDOTDIR": directory + "/zsh"])
        #expect(FileManager.default.fileExists(atPath: directory + "/zsh/.zshenv"))
        let own = try ShellIntegration.environment(
            for: ["zsh"],
            inherited: ["ZDOTDIR": "/my/dots"],
            directory: directory
        )
        #expect(own == ["ZDOTDIR": directory + "/zsh", "SUNSET_ZDOTDIR": "/my/dots"])
    }

    @Test func `a real zsh marks each prompt and says how the command ended, and still reads the user's files`() throws
    {
        let directory = try temporary("install")
        let dots = try temporary("dots")
        try "export FROM_ENV=env\n".write(toFile: dots + "/.zshenv", atomically: true, encoding: .utf8)
        try "PS1='> '\nFROM_RC=rc\n".write(toFile: dots + "/.zshrc", atomically: true, encoding: .utf8)
        var environment = ["ZDOTDIR": dots, "HOME": dots, "TERM": "xterm-256color"]
        let added = try ShellIntegration.environment(
            for: ["/bin/zsh", "-i"],
            inherited: environment,
            directory: directory
        )
        for (key, value) in added { environment[key] = value }
        let session = try HeadlessSession(["/bin/zsh", "-i"], columns: 160, rows: 10, environment: environment)
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } })
        try session.send("echo $FROM_ENV $FROM_RC ${ZDOTDIR##*/} ${+SUNSET_ZDOTDIR}; false\n")
        #expect(session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count == 2 })
        let marks = session.terminal.screen.promptMarks
        #expect(marks.map(\.kind) == [.promptStart, .outputStart, .commandEnd, .promptStart])
        #expect(marks.first { $0.kind == .commandEnd }?.exitStatus == 1)
        let dotsName = dots.split(separator: "/").last.map(String.init) ?? ""
        #expect(session.lines.contains("env rc \(dotsName) 0"), "\(session.lines)")
        try session.send("exit\n")
        #expect(session.waitForExit())
    }

    private static let fish = ["/opt/homebrew/bin/fish", "/usr/local/bin/fish"]
        .first {
            FileManager.default.isExecutableFile(atPath: $0)
        }

    /// fish (4 and later) marks its prompts by itself, which is why it is not taught: this holds the reason true on a machine that has it.
    @Test(.enabled(if: fish != nil)) func `fish marks its prompts with nothing added`() throws {
        let home = try temporary("fish")
        let environment = ["HOME": home, "XDG_CONFIG_HOME": home, "TERM": "xterm-256color"]
        #expect(
            try ShellIntegration.environment(for: [Self.fish ?? "fish"], inherited: environment, directory: home)
                .isEmpty
        )
        let session = try HeadlessSession([Self.fish ?? "fish", "-i"], columns: 120, rows: 10, environment: environment)
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } })
        try session.send("false\n")
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .commandEnd && $0.exitStatus == 1 } })
        try session.send("exit\n")
        #expect(session.waitForExit())
    }
}
