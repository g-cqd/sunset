import Foundation

/// What the command line asked for: the program to run in the window, and settings that override the stored ones for this launch.
struct LaunchOptions: Sendable {
    var command: [String]
    var fontName: String?
    var fontSize: Double?
    var ligatures: Bool?
    var scrollback: Int?
    /// A program was named on the command line: this launch is for that program, not for the saved tabs.
    var namedCommand = false

    /// `sunset-app [--font NAME] [--size PT] [--ligatures] [--scrollback LINES] [-- command [args...]]`; the user's shell (as a login shell) when no command is given.
    static func parse(_ arguments: [String], environment: [String: String]) -> LaunchOptions {
        var options = LaunchOptions(command: [])
        var rest = arguments.dropFirst()
        while let argument = rest.first {
            rest = rest.dropFirst()
            switch argument {
                case "--font": options.fontName = rest.popFirst()
                case "--size": options.fontSize = rest.popFirst().flatMap(Double.init)
                case "--ligatures": options.ligatures = true
                case "--scrollback": options.scrollback = rest.popFirst().flatMap(Int.init)
                case "--":
                    options.command = Array(rest)
                    rest = []
                default:
                    // Anything else (the system passes `-NS…` and `-psn_…` flags) is not ours.
                    if !argument.hasPrefix("-") {
                        options.command = [argument] + Array(rest)
                        rest = []
                    }
            }
        }
        options.namedCommand = !options.command.isEmpty
        if options.command.isEmpty { options.command = [environment["SHELL"] ?? "/bin/zsh", "-l"] }
        return options
    }
}
