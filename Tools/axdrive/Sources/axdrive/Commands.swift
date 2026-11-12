import ApplicationServices
import Foundation

enum Commands {
    static func run(_ options: Options) async -> Int32 {
        let pid = options.pid
        if Steps.acting.contains(options.command),
            options.values["expect"] != nil || options.values["expect-gone"] != nil
        {
            return await Steps.checked(options)
        }
        switch options.command {
            case "windows", "tree", "find": return list(options)
            case "expect": return await wait(options)
            case "value": return await Steps.value(options)
            case "press":
                guard let node = await chosen(options) else { return lastFailure }
                let action =
                    options.values["action"]
                    ?? (node.actions.contains(kAXPressAction) ? kAXPressAction : node.actions.first ?? kAXPressAction)
                return perform(node, action)
            case "set":
                guard options.words.count >= 2, let node = await chosen(options) else { return lastFailure }
                let status = AXUIElementSetAttributeValue(
                    node.element,
                    kAXValueAttribute as CFString,
                    options.words[1] as CFString
                )
                guard status == .success else {
                    return fail("could not set the value (\(status.rawValue)) of \(node.summary)")
                }
                return options.flags.contains("confirm") ? perform(node, kAXConfirmAction) : 0
            case "focus":
                guard let node = await chosen(options) else { return lastFailure }
                let status = AXUIElementSetAttributeValue(node.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                return status == .success ? 0 : fail("could not focus (\(status.rawValue)) \(node.summary)")
            case "menu": return Menus.press(pid: pid, path: options.words.first ?? "")
            case "main": return Windows.makeMain(pid: pid, title: options.words.first)
            case "type":
                return await Typing.type(options.words.joined(separator: " "), pid: pid, into: options.values["into"])
            case "key":
                return Keys.chord(options.words.first ?? "", pid: pid)
                    ? 0 : fail("unknown key \(options.words.first ?? "")")
            case "wait": return await wait(options)
            case "shot":
                return Capture.shot(
                    pid: pid,
                    to: options.words.first ?? "/tmp/axdrive.png",
                    window: options.values["window"]
                ) ? 0 : 3
            default:
                print(usage)
                return 3
        }
    }

    static func list(_ options: Options) -> Int32 {
        let pid = options.pid
        switch options.command {
            case "windows":
                for window in Capture.windows(pid: pid) {
                    print(
                        window.id,
                        "\"\(window.title)\"",
                        Int(window.bounds.minX),
                        Int(window.bounds.minY),
                        Int(window.bounds.width),
                        Int(window.bounds.height)
                    )
                }
                return 0
            case "tree":
                for node in nodes(options) where node.path.split(separator: "/").count <= options.int("depth", 12) {
                    print(String(repeating: "  ", count: node.path.split(separator: "/").count - 1) + node.summary)
                }
                return 0
            case "find":
                let matches = ranked(options)
                for (index, match) in matches.prefix(options.int("limit", 10)).enumerated() {
                    print("\(index) t\(match.tier) \(Int(match.score)) \(match.node.summary)")
                }
                return matches.isEmpty ? 1 : 0
            default: return 3
        }
    }

    nonisolated(unsafe) static var lastFailure: Int32 = 1

    static func nodes(_ options: Options) -> [Node] {
        Tree.nodes(
            pid: options.pid,
            windowFilter: options.values["window"],
            includeMenus: options.flags.contains("menus")
        )
    }

    static func ranked(_ options: Options) -> [Match] {
        Ranking.rank(nodes(options), query: options.words.first ?? "", role: options.values["role"])
    }

    /// The element the query means: the clear winner, the one picked (`--pick`), or the one the on-device model picks for `--ask`.
    static func chosen(_ options: Options) async -> Node? {
        // The target may still be appearing (a panel, a page loading): looked for again until it is there and enabled.
        let deadline = Date().addingTimeInterval(options.double("within", 3))
        var matches = ranked(options)
        while Date() < deadline, matches.first.map({ !$0.node.enabled }) ?? true {
            try? await Task.sleep(for: .milliseconds(80))
            matches = ranked(options)
        }
        guard !matches.isEmpty else {
            lastFailure = fail("nothing matches \"\(options.words.first ?? "")\"")
            return nil
        }
        if let pick = options.values["pick"].flatMap(Int.init) {
            guard matches.indices.contains(pick) else {
                lastFailure = fail("no candidate \(pick)")
                return nil
            }
            return matches[pick].node
        }
        if let winner = Ranking.clearWinner(matches) { return winner.node }
        if let goal = options.values["ask"], let index = await Chooser.choose(goal: goal, among: matches) {
            FileHandle.standardError.write(
                Data("axdrive: the model chose \(index): \(matches[index].node.summary)\n".utf8)
            )
            return matches[index].node
        }
        print("ambiguous; candidates:")
        for (index, match) in matches.prefix(8).enumerated() {
            print("\(index) t\(match.tier) \(Int(match.score)) \(match.node.summary)")
        }
        lastFailure = 2
        return nil
    }

    static func perform(_ node: Node, _ action: String) -> Int32 {
        guard node.enabled else { return fail("\(node.summary) is disabled") }
        let status = AXUIElementPerformAction(node.element, action as CFString)
        if status == .success {
            print("\(action) \(node.summary)")
            return 0
        }
        return fail("\(action) failed (\(status.rawValue)) on \(node.summary); its actions: \(node.actions)")
    }

    static func wait(_ options: Options) async -> Int32 {
        let deadline = Date().addingTimeInterval(options.double("timeout", 10))
        while Date() < deadline {
            let present = !ranked(options).isEmpty
            if present != options.flags.contains("gone") { return 0 }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return fail(
            "timed out waiting for \"\(options.words.first ?? "")\"\(options.flags.contains("gone") ? " to go" : "")"
        )
    }

    @discardableResult
    static func fail(_ message: String) -> Int32 {
        FileHandle.standardError.write(Data("axdrive: \(message)\n".utf8))
        return 3
    }
}
