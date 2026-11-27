/// What the command bar learnt of the commands run from it: how often each was, and the command what was typed last ran.
/// The command learnt for what is typed again comes first, before the tabs and what the web would do; the others of a
/// query by how often they were run. Only words typed to find a command are kept, not what else was typed.
package struct CommandLearning: Equatable, Sendable {
    /// At most this many typed queries are kept: the oldest go first.
    static let limit = 200

    private(set) var uses: [AppCommand.ID: Int] = [:]
    /// What was typed, lowercased and trimmed, and the command it ran; in the order they were last run.
    private(set) var learnt: [(typed: String, command: AppCommand.ID)] = []

    package init() {}

    package static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uses == rhs.uses && lhs.learnt.map(\.typed) == rhs.learnt.map(\.typed)
            && lhs.learnt.map(\.command) == rhs.learnt.map(\.command)
    }

    private static func key(_ typed: String) -> String {
        typed.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// `command` was run from the bar with `typed` in its field.
    package mutating func ran(_ command: AppCommand.ID, typed: String) {
        uses[command, default: 0] += 1
        let key = Self.key(typed)
        guard !key.isEmpty else { return }
        learnt.removeAll { $0.typed == key }
        learnt.append((key, command))
        if learnt.count > Self.limit { learnt.removeFirst(learnt.count - Self.limit) }
    }

    /// The command `typed` ran last time.
    package func command(for typed: String) -> AppCommand.ID? {
        let key = Self.key(typed)
        return learnt.last { $0.typed == key }?.command
    }

    /// How often `command` was run from the bar.
    package func uses(of command: AppCommand.ID) -> Int {
        uses[command] ?? 0
    }

    /// As kept between launches: "typed\tcommand" lines, then "#command\tcount" lines.
    package var saved: [String] {
        learnt.map { "\($0.typed)\t\($0.command.rawValue)" }
            + uses.sorted { $0.key.rawValue < $1.key.rawValue }.map { "#\($0.key.rawValue)\t\($0.value)" }
    }

    /// Read back from `saved`; what is not one of its lines is left out.
    package init(saved lines: [String]) {
        for line in lines {
            let parts = line.split(separator: "\t", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            if parts[0].hasPrefix("#") {
                if let id = AppCommand.ID(rawValue: String(parts[0].dropFirst())), let count = Int(parts[1]) {
                    uses[id] = count
                }
            } else if let id = AppCommand.ID(rawValue: parts[1]) {
                learnt.append((parts[0], id))
            }
        }
        if learnt.count > Self.limit { learnt.removeFirst(learnt.count - Self.limit) }
    }
}
