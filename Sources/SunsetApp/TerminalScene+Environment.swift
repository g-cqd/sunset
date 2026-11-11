import Foundation
import SunsetHost

extension TerminalScene {
    /// What a new shell is started with: the app's environment, what says which terminal this is, and, when `integrated`, what teaches the shell to mark
    /// its prompts (`ShellIntegration`). A shell that cannot be taught starts as it is.
    static func shellEnvironment(for command: [String], integrated: Bool) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["TERM_PROGRAM"] = "sunset"
        environment["COLORTERM"] = "truecolor"
        environment["TERM"] = "xterm-256color"
        guard integrated else { return environment }
        let directory = SessionStore.directory + "/shell"
        let added = try? ShellIntegration.environment(for: command, inherited: environment, directory: directory)
        for (key, value) in added ?? [:] { environment[key] = value }
        return environment
    }
}
