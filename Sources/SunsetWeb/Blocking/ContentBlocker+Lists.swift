import CryptoKit
import Foundation
import WebKit

/// The lists, compiled once (task t109, diary 2026-11-19-08). A list's compiled parts are named by a digest of its text and
/// of the converter's version, so a launch with the same lists looks them up (under 1 ms) instead of converting and
/// compiling them again (0.77 s of the main thread and 2.9 s of compiling for EasyList and EasyPrivacy). The conversion runs
/// off the main actor. What no list uses any more is taken out of WebKit's store.
extension ContentBlocker {
    /// Changed whenever `BlockingRules` changes what it makes: every list is then compiled again once.
    static let converterVersion = "2"

    /// What one list became: its parts as WebKit's JSON, and what Settings say of it.
    struct Prepared: Sendable {
        var parts: [String]
        var rules: Int
        var skipped: Int
    }

    /// What is kept beside a list's compiled parts: how many there are, and its counts for Settings.
    struct Kept: Codable {
        var parts: Int
        var rules: Int
        var skipped: Int
    }

    /// Converts and encodes a list, off the main actor: pure work on a list's text.
    @concurrent
    static func prepare(_ text: String) async -> Prepared {
        let converted = BlockingRules.convert(text)
        let parts = converted.parts().compactMap { try? BlockingRules.json($0) }
            .map { String(decoding: $0, as: UTF8.self) }
        return Prepared(parts: parts, rules: converted.rules.count, skipped: converted.skipped)
    }

    /// The name of a list's compiled parts: its text and the converter's version, digested.
    static func key(_ text: String) -> String {
        let digest = SHA256.hash(data: Data((converterVersion + "\n" + text).utf8))
        return "list-" + digest.prefix(12).map { String(format: "%02x", $0) }.joined()
    }

    /// Looks each list up, or converts and compiles it once; then puts them on every page and removes what no list uses.
    /// A list that does not compile is said in its state and left out; the others are used.
    package func load(_ sources: [Source]) async {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let store = WKContentRuleListStore(url: folder) else { return }
        var lists: [WKContentRuleList] = []
        var states: [ListState] = []
        var used: Set<String> = []
        for source in sources {
            let key = Self.key(source.text)
            var state = ListState(address: source.address, rules: 0, skipped: 0, updated: source.updated)
            if let kept = readKept(key), let found = await lookUp(key, parts: kept.parts, in: store) {
                lists += found
                state.rules = kept.rules
                state.skipped = kept.skipped
            } else {
                let made = await Self.prepare(source.text)
                state.rules = made.rules
                state.skipped = made.skipped
                do {
                    for (index, json) in made.parts.enumerated() {
                        compilations += 1
                        if let list = try await store.compileContentRuleList(
                            forIdentifier: "\(key)-\(index)",
                            encodedContentRuleList: json
                        ) {
                            lists.append(list)
                        }
                    }
                    writeKept(key, Kept(parts: made.parts.count, rules: made.rules, skipped: made.skipped))
                } catch {
                    state.problem = "WebKit could not compile it: \(error.localizedDescription)"
                }
            }
            if state.problem == nil { used.insert(key) }
            states.append(state)
        }
        compiled = lists
        self.states = states
        reapplyAll()
        await removeUnused(keeping: used, in: store)
    }

    private func lookUp(_ key: String, parts: Int, in store: WKContentRuleListStore) async -> [WKContentRuleList]? {
        var found: [WKContentRuleList] = []
        for index in 0 ..< parts {
            guard let list = try? await store.contentRuleList(forIdentifier: "\(key)-\(index)") else { return nil }
            found.append(list)
        }
        return found
    }

    /// Takes out of WebKit's store the lists' parts no list uses (the hidden elements' lists are not the lists').
    private func removeUnused(keeping used: Set<String>, in store: WKContentRuleListStore) async {
        for identifier in await store.availableIdentifiers() ?? [] where identifier.hasPrefix("list-") {
            let key = identifier.split(separator: "-").prefix(2).joined(separator: "-")
            guard !used.contains(key) else { continue }
            try? await store.removeContentRuleList(forIdentifier: identifier)
            try? FileManager.default.removeItem(at: keptFile(key))
        }
    }

    private func keptFile(_ key: String) -> URL {
        folder.appending(path: key + ".json")
    }

    private func readKept(_ key: String) -> Kept? {
        (try? Data(contentsOf: keptFile(key))).flatMap { try? JSONDecoder().decode(Kept.self, from: $0) }
    }

    private func writeKept(_ key: String, _ kept: Kept) {
        try? JSONEncoder().encode(kept).write(to: keptFile(key), options: .atomic)
    }
}
