import ApplicationServices
import Foundation

/// An action with its proof (`--expect TEXT`, `--expect-gone TEXT`): done, then the expected change waited for; when it does not come and the
/// target is still there (the press did not land), done once more; never twice when the target went (it acted). A failure says what was seen.
enum Steps {
    static let acting: Set<String> = ["press", "set", "focus", "menu", "type", "key"]

    static func checked(_ options: Options) async -> Int32 {
        var plain = options
        plain.values["expect"] = nil
        plain.values["expect-gone"] = nil
        for attempt in 1 ... 2 {
            let status = await Commands.run(plain)
            guard status == 0 else { return status }
            if await expectation(options) { return 0 }
            let retryable =
                attempt == 1 && ["press", "set", "focus"].contains(options.command)
                && !Commands.ranked(plain).isEmpty
            guard retryable else { break }
            FileHandle.standardError.write(Data("axdrive: no effect seen; once more\n".utf8))
        }
        let what =
            options.values["expect"].map { "\"\($0)\" to appear" } ?? "\"\(options.values["expect-gone"] ?? "")\" to go"
        return Commands.fail("\(options.command) \(options.words.first ?? "") done, but no \(what)")
    }

    /// Waits for the expected text to appear (or to go), within `--timeout` (5 s).
    static func expectation(_ options: Options) async -> Bool {
        var probe = options
        probe.values["role"] = options.values["expect-role"]
        probe.values["expect"] = nil
        let gone = options.values["expect-gone"] != nil
        probe.words = [options.values["expect"] ?? options.values["expect-gone"] ?? ""]
        let deadline = Date().addingTimeInterval(options.double("timeout", 5))
        repeat {
            // Only real matches count as proof (not the letters-in-order tier).
            if Commands.ranked(probe).filter({ $0.tier <= 4 }).isEmpty == gone { return true }
            try? await Task.sleep(for: .milliseconds(80))
        } while Date() < deadline
        return false
    }

    /// `value QUERY TEXT`: the element's value holds TEXT (waited for, `--timeout`).
    static func value(_ options: Options) async -> Int32 {
        guard options.words.count >= 2 else { return Commands.fail("value QUERY TEXT") }
        let wanted = Ranking.normalized(options.words[1])
        let deadline = Date().addingTimeInterval(options.double("timeout", 5))
        var seen = ""
        repeat {
            if let node = Ranking.clearWinner(Commands.ranked(options))?.node {
                seen = Node.string(node.element, kAXValueAttribute)
                if Ranking.normalized(seen).contains(wanted) { return 0 }
            }
            try? await Task.sleep(for: .milliseconds(80))
        } while Date() < deadline
        return Commands.fail(
            "the value of \(options.words[0]) is \"\(seen.prefix(80))\", not holding \"\(options.words[1])\""
        )
    }
}
