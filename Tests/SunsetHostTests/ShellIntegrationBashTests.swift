import Foundation
import SunsetCore
import Testing

@testable import SunsetHost

/// bash keeps the user's own prompt commands and DEBUG trap: Sunset's hooks are added around them, never in their place,
/// and the user's prompt commands are not taken for commands the user ran.
@Suite("Shell integration: bash coexists", .serialized) struct ShellIntegrationBashTests {
    static let bashes: [String] = ["/bin/bash", "/opt/homebrew/bin/bash"]
        .filter { FileManager.default.isExecutableFile(atPath: $0) }

    private func session(_ shell: String, bashrc: String) throws -> (HeadlessSession, String) {
        let base = NSTemporaryDirectory() + "sunset-bash-\(UUID().uuidString)"
        let home = base + "/home"
        try FileManager.default.createDirectory(atPath: home, withIntermediateDirectories: true)
        try bashrc.write(toFile: home + "/.bashrc", atomically: true, encoding: .utf8)
        let inherited = ["HOME": home, "TERM": "xterm-256color", "LANG": "en_US.UTF-8"]
        let prepared = try ShellIntegration.prepare(
            command: [shell, "-i"],
            inherited: inherited,
            directory: base + "/int"
        )
        let environment = inherited.merging(prepared.environment) { _, added in added }
        return (try HeadlessSession(prepared.command, columns: 200, rows: 12, environment: environment), base)
    }

    @Test(arguments: bashes)
    func `the user's PROMPT_COMMAND runs and is not marked as a command`(shell: String) throws {
        let (session, base) = try session(shell, bashrc: "PS1='$ '\nPROMPT_COMMAND='USER_PC=$((USER_PC+1))'\n")
        defer { try? FileManager.default.removeItem(atPath: base) }
        func marks() -> [PromptMark] {
            session.terminal.screen.promptMarks
        }
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } })
        // An empty line runs nothing: a new prompt, and no command's start or end.
        try session.send("\n")
        #expect(session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count == 2 })
        #expect(marks().map(\.kind) == [.promptStart, .promptStart], "\(shell): \(marks())")
        // A command's output starts below the prompt it was typed at, and its end carries its status.
        try session.send("false\n")
        #expect(session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count == 3 })
        let kinds = marks().map(\.kind)
        #expect(kinds == [.promptStart, .promptStart, .outputStart, .commandEnd, .promptStart], "\(shell): \(kinds)")
        let prompt = marks().filter { $0.kind == .promptStart }[1].stableLine
        let output = marks().first { $0.kind == .outputStart }?.stableLine ?? -1
        #expect(output > prompt, "\(shell): output started on line \(output), the prompt was on \(prompt)")
        #expect(marks().first { $0.kind == .commandEnd }?.exitStatus == 1)
        try session.send("echo pc=$USER_PC\n")
        #expect(session.wait { _ in session.lines.contains { $0.hasPrefix("pc=") } })
        #expect(session.lines.contains("pc=3"), "\(shell): \(session.lines)")
        try session.send("exit\n")
        #expect(session.waitForExit())
    }

    @Test(.enabled(if: FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/bash")))
    func `bash 5's PROMPT_COMMAND array keeps every element`() throws {
        let rc = "PS1='$ '\nPROMPT_COMMAND=('USER_A=$((USER_A+1))' 'USER_B=$((USER_B+1))')\n"
        let (session, base) = try session("/opt/homebrew/bin/bash", bashrc: rc)
        defer { try? FileManager.default.removeItem(atPath: base) }
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } })
        try session.send("\n")
        #expect(session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count == 2 })
        try session.send("false\n")
        #expect(session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count == 3 })
        let kinds = session.terminal.screen.promptMarks.map(\.kind)
        #expect(kinds == [.promptStart, .promptStart, .outputStart, .commandEnd, .promptStart], "\(kinds)")
        try session.send("echo ab=$USER_A$USER_B\n")
        #expect(session.wait { _ in session.lines.contains { $0.hasPrefix("ab=") } })
        #expect(session.lines.contains("ab=33"), "\(session.lines)")
        try session.send("exit\n")
        #expect(session.waitForExit())
    }

    @Test(arguments: bashes)
    func `the user's DEBUG trap is kept`(shell: String) throws {
        let (session, base) = try session(shell, bashrc: "PS1='$ '\ntrap 'USER_TRAP=$((USER_TRAP+1))' DEBUG\n")
        defer { try? FileManager.default.removeItem(atPath: base) }
        #expect(session.wait { $0.screen.promptMarks.contains { $0.kind == .promptStart } })
        try session.send("trap -p DEBUG\n")
        #expect(session.wait { _ in session.lines.contains { $0.hasPrefix("trap -- ") } })
        let shown = session.lines.first { $0.hasPrefix("trap -- ") } ?? ""
        #expect(shown.contains("USER_TRAP"), "\(shell): the DEBUG trap is now \(shown)")
        // It still runs: the count goes up between two commands.
        try session.send("A=$USER_TRAP; B=$USER_TRAP; echo ran=$(( B > A ))\n")
        #expect(session.wait { _ in session.lines.contains { $0.hasPrefix("ran=") } })
        #expect(session.lines.contains("ran=1"), "\(shell): \(session.lines)")
        // With the user's trap, prompts are still marked; commands are not (no start, no end with a status).
        let kinds = Set(session.terminal.screen.promptMarks.map(\.kind))
        #expect(kinds == [.promptStart], "\(shell): \(kinds)")
        try session.send("exit\n")
        #expect(session.waitForExit())
    }
}
