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
        // Taught zsh also reports its working directory via OSC 7 on each prompt (T-2 / t186).
        #expect(session.terminal.screen.workingDirectory != nil)
        try session.send("exit\n")
        #expect(session.waitForExit())
    }

    @Test func `bash is taught via rcfile, reports prompts and working directory, and still reads user dotfiles`()
        throws
    {
        let directory = try temporary("bash-int")
        let home = try temporary("bash-home")
        try "export FROM_BASHRC=yes\nPS1='$ '\n".write(toFile: home + "/.bashrc", atomically: true, encoding: .utf8)
        let baseEnv = ["HOME": home, "TERM": "xterm-256color"]
        let prepared = try ShellIntegration.prepare(
            command: ["/bin/bash", "-i"],
            inherited: baseEnv,
            directory: directory
        )
        #expect(prepared.command.contains("--rcfile"))
        var env = baseEnv
        for (k, v) in prepared.environment { env[k] = v }

        let session = try HeadlessSession(prepared.command, columns: 160, rows: 10, environment: env)
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } })
        #expect(session.terminal.screen.workingDirectory != nil)
        try session.send("echo $FROM_BASHRC; false\n")
        #expect(session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count >= 2 })
        let marks = session.terminal.screen.promptMarks
        #expect(marks.contains { $0.kind == .commandEnd && $0.exitStatus == 1 })
        #expect(session.lines.contains("yes"), "\(session.lines)")
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
        // fish starts slowly while the whole suite runs beside it (its first prompt took over 5 s once in three runs); a wait
        // ends as soon as its condition holds, so a long limit costs nothing when fish is quick.
        let patient = 30000
        #expect(
            session.wait(timeoutMilliseconds: patient) { $0.screen.promptMarks.contains { $0.kind == .promptStart } }
        )
        try session.send("false\n")
        #expect(
            session.wait(timeoutMilliseconds: patient) {
                $0.screen.promptMarks.contains { $0.kind == .commandEnd && $0.exitStatus == 1 }
            }
        )
        try session.send("exit\n")
        #expect(session.waitForExit(timeoutMilliseconds: patient))
    }
}
