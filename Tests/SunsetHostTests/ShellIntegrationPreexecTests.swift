import Foundation
import SunsetCore
import Testing

@testable import SunsetHost

/// bash-preexec (the hooks atuin, starship and others build on) owns PROMPT_COMMAND and the DEBUG trap (PS0 on bash 5.3):
/// with it loaded, Sunset's hooks are among its precmd and preexec functions, so commands are marked and the user's
/// hooks still run, with the command and the status they expect. Against an unmodified bash-preexec 0.7.0 (Fixtures).
@Suite("Shell integration: bash beside bash-preexec", .serialized) struct ShellIntegrationPreexecTests {
    static let preexec = Bundle.module.path(forResource: "Fixtures/bash-preexec/bash-preexec", ofType: "sh") ?? ""

    /// The user's hooks: the command line before the one running, how many prompts, and the status each prompt saw.
    static let bashrc = """
        PS1='$ '
        source '\(preexec)'
        user_preexec() { USER_LAST="${USER_NOW:-}"; USER_NOW="$1"; }
        user_precmd() { USER_STATUS=$?; USER_PROMPTS=$((USER_PROMPTS+1)); }
        preexec_functions+=(user_preexec)
        precmd_functions+=(user_precmd)

        """

    @Test(arguments: ShellIntegrationBashTests.bashes)
    func `commands are marked, once each, and the user's hooks run as before`(shell: String) throws {
        #expect(FileManager.default.fileExists(atPath: Self.preexec))
        let (session, base) = try ShellIntegrationBashTests().session(shell, bashrc: Self.bashrc)
        defer { try? FileManager.default.removeItem(atPath: base) }
        func kinds() -> [PromptMark.Kind] {
            session.terminal.screen.promptMarks.map(\.kind)
        }
        func prompts(_ count: Int) -> Bool {
            session.wait { $0.screen.promptMarks.filter { $0.kind == .promptStart }.count == count }
        }
        #expect(prompts(1))
        // An empty line runs nothing; a line of two commands is one command, ending with the last one's status.
        try session.send("\n")
        #expect(prompts(2))
        #expect(kinds() == [.promptStart, .promptStart], "\(shell): \(kinds())")
        try session.send("true; false\n")
        #expect(prompts(3))
        #expect(
            kinds() == [.promptStart, .promptStart, .outputStart, .commandEnd, .promptStart],
            "\(shell): \(kinds())"
        )
        let marks = session.terminal.screen.promptMarks
        let prompt = marks.filter { $0.kind == .promptStart }[1].stableLine
        let output = marks.first { $0.kind == .outputStart }?.stableLine ?? -1
        #expect(output > prompt, "\(shell): output started on line \(output), the prompt was on \(prompt)")
        #expect(marks.first { $0.kind == .commandEnd }?.exitStatus == 1)
        // The user's preexec saw the line, their precmd the status and every prompt; bash-preexec kept its hooks.
        try session.send(
            "echo \"last=$USER_LAST status=$USER_STATUS prompts=$USER_PROMPTS\"; trap -p DEBUG; echo \"pc=$PROMPT_COMMAND\"\n"
        )
        #expect(session.wait { _ in session.lines.contains { $0.hasPrefix("pc=") } })
        let lines = session.lines
        #expect(lines.contains("last=true; false status=1 prompts=3"), "\(shell): \(lines)")
        #expect(!lines.contains { $0.contains("_sunset_preexec") || $0.contains("_sunset_arm") }, "\(shell): \(lines)")
        #expect(lines.contains { $0.hasPrefix("pc=__bp_precmd_invoke_cmd") }, "\(shell): \(lines)")
        #expect(prompts(4))
        #expect(
            kinds().count == 8 && kinds()[5...] == [.outputStart, .commandEnd, .promptStart],
            "\(shell): \(kinds())"
        )
        try session.send("exit\n")
        #expect(session.waitForExit())
    }
}
