import Foundation

/// The structure rules of the family (ask's ADR-0021, AemiFormal's ADR-0004): a Swift file declares one top-level type and is named for it, and no file runs
/// past 250 lines, tests included, so that the file listing is the map of the types the project owns. Generated files (named `Generated…`) are exempt.
enum SourceStructure {
    static let maximumLines = 250

    /// What is wrong with a set of Swift files, one sentence each; empty when they are sound.
    static func problems(in files: [(name: String, text: String)]) -> [String] {
        var problems: [String] = []
        for file in files where !file.name.hasPrefix("Generated") {
            let lines = file.text.split(separator: "\n", omittingEmptySubsequences: false).count - 1
            if lines > maximumLines { problems.append("\(file.name): \(lines) lines, over \(maximumLines)") }
            problems += namingProblems(of: file)
        }
        return problems
    }

    private static func namingProblems(of file: (name: String, text: String)) -> [String] {
        let stem = String(file.name.dropLast(".swift".count))
        let owner = String(stem.split(separator: "+", omittingEmptySubsequences: false).first ?? "")
        let (types, extensions) = declarations(in: file.text)
        if types.count > 1 {
            return ["\(file.name): declares \(types.count) top-level types (\(types.joined(separator: ", ")))"]
        }
        if let type = types.first {
            return type == owner || file.name == "main.swift"
                ? [] : ["\(file.name): declares \(type), so the file should be named \(type).swift or \(type)+….swift"]
        }
        guard let first = extensions.first else { return [] }
        if Set(extensions).count > 1 {
            return ["\(file.name): extends several types (\(Set(extensions).sorted().joined(separator: ", ")))"]
        }
        let expected = first.replacingOccurrences(of: ".", with: "+")
        return stem == expected || stem.hasPrefix(expected + "+")
            ? [] : ["\(file.name): extends \(first), so the file should be named \(expected)+….swift"]
    }

    /// The names of the top-level types and the types extended at the top level of `text`, in order. A declaration is a line that starts in column 0, after
    /// any attributes (with their arguments) and modifiers; comments and strings are not looked into.
    static func declarations(in text: String) -> (types: [String], extensions: [String]) {
        var types: [String] = []
        var extensions: [String] = []
        let keywords: Set<String> = ["struct", "class", "enum", "protocol", "actor"]
        let modifiers: Set<String> = [
            "public", "internal", "private", "fileprivate", "final", "indirect", "package", "open", "nonisolated"
        ]
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let first = line.first, first != " ", first != "\t", first != "}", first != "/", first != "\"" else {
                continue
            }
            var words = withoutAttributes(String(line)).split(whereSeparator: { " (:{<".contains($0) }).map(String.init)
            while let head = words.first, modifiers.contains(head) { words.removeFirst() }
            guard words.count >= 2 else { continue }
            if keywords.contains(words[0]) {
                types.append(words[1])
            } else if words[0] == "extension" {
                extensions.append(words[1])
            }
        }
        return (types, extensions)
    }

    /// The line without its leading attributes: `@Suite("name") @MainActor struct X` becomes `struct X`.
    private static func withoutAttributes(_ line: String) -> String {
        var rest = Substring(line)
        while rest.hasPrefix("@") {
            var depth = 0
            var end = rest.startIndex
            scan: for index in rest.indices {
                end = index
                switch rest[index] {
                    case "(": depth += 1
                    case ")": depth -= 1
                    case " " where depth == 0: break scan
                    default: continue
                }
            }
            rest = rest[end...].drop { $0 == " " }
        }
        return String(rest)
    }
}
