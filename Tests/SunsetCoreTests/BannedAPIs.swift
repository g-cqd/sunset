/// APIs this repository does not use, and why (docs/quality.md). A match in a comment counts too: say it another way.
enum BannedAPIs {
    struct Rule {
        var name: String
        var needles: [String]
        var reason: String
    }

    static let rules = [
        Rule(
            name: "Grand Central Dispatch",
            needles: [
                "import Dispatch", "DispatchQueue", "DispatchSource", "DispatchSemaphore", "DispatchGroup",
                "DispatchWorkItem", "DispatchTime",
                "DispatchIO"
            ],
            reason:
                "owner note n7: Swift concurrency and executors only (blocking work runs on `DedicatedThread`, a task executor)"
        )
    ]

    /// One sentence per use of a banned API in `files`; empty when there is none.
    static func problems(in files: [(name: String, text: String)], rules: [Rule] = rules) -> [String] {
        var problems: [String] = []
        for file in files {
            for (offset, line) in file.text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                for rule in rules {
                    for needle in rule.needles where line.contains(needle) {
                        problems.append("\(file.name):\(offset + 1): \(needle) (\(rule.name): \(rule.reason))")
                    }
                }
            }
        }
        return problems
    }
}
