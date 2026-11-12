import Darwin

/// The command line: a command, a process id, its positional words, and `--name value` options (`--menus` and `--gone` stand alone).
struct Options {
    var command = ""
    var pid: pid_t = 0
    var words: [String] = []
    var values: [String: String] = [:]
    var flags: Set<String> = []

    static let alone: Set<String> = ["menus", "gone", "confirm", "all"]

    init(_ arguments: [String]) {
        var rest = arguments.dropFirst()
        command = rest.popFirst() ?? ""
        pid = rest.popFirst().flatMap { pid_t($0) } ?? 0
        while let word = rest.popFirst() {
            if word.hasPrefix("--") {
                let name = String(word.dropFirst(2))
                if Self.alone.contains(name) { flags.insert(name) } else { values[name] = rest.popFirst() ?? "" }
            } else {
                words.append(word)
            }
        }
    }

    func int(_ name: String, _ fallback: Int) -> Int { values[name].flatMap(Int.init) ?? fallback }
    func double(_ name: String, _ fallback: Double) -> Double { values[name].flatMap(Double.init) ?? fallback }
}
