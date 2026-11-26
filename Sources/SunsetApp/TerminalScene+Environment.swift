import Foundation
import SunsetCore
import SunsetHost

extension TerminalScene {
    /// Prepares command arguments and environment for a new shell: sets Sunset's standard `TERM_*` variables and, when
    /// `integrated` is true, applies `ShellIntegration.prepare` for zsh and bash.
    static func shellLaunch(for command: [String], integrated: Bool) -> ShellIntegration.Prepared {
        var environment = ProcessInfo.processInfo.environment
        environment["TERM_PROGRAM"] = "sunset"
        environment["TERM_PROGRAM_VERSION"] = "\(Sunset.version)"
        environment["COLORTERM"] = "truecolor"
        environment["TERM"] = "xterm-256color"
        guard integrated else { return ShellIntegration.Prepared(command: command, environment: environment) }
        let directory = SessionStore.directory + "/shell"
        let prepared =
            (try? ShellIntegration.prepare(command: command, inherited: environment, directory: directory))
            ?? ShellIntegration.Prepared(command: command, environment: [:])
        for (key, value) in prepared.environment { environment[key] = value }
        return ShellIntegration.Prepared(command: prepared.command, environment: environment)
    }
}
