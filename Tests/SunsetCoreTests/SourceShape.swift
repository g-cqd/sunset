import Foundation

/// The code's shape: no declaration has its body on its own line. A body is that of a `func`, `init`, `subscript`,
/// `deinit`, a computed `var` or an accessor; a protocol's requirement (`{ get }`) is not one. The same reading as
/// `Scripts/tools/expand-one-line-bodies.py`, which spans them over lines.
enum SourceShape {
    private static let keywords: Set<String> = [
        "func", "init", "init?", "init!", "subscript", "deinit", "var", "get", "set", "didSet", "willSet"
    ]

    private static let modifiers: Set<String> = [
        "public", "package", "private", "fileprivate", "internal", "open", "static", "class", "final", "override",
        "nonisolated", "mutating", "nonmutating", "lazy", "weak", "unowned", "convenience", "required", "dynamic",
        "indirect", "consuming", "borrowing", "private(set)", "package(set)", "internal(set)", "fileprivate(set)",
        "public(set)"
    ]

    private static let requirements: Set<String> = [
        "get", "set", "get set", "set get", "get async", "get throws", "get async throws", "nonmutating set",
        "get nonmutating set", "mutating get"
    ]

    /// Each one-line body in `files`, as `file:line: text`.
    static func oneLineBodies(in files: [(name: String, text: String)]) -> [String] {
        var found: [String] = []
        for file in files {
            let lines = file.text.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() where isOneLineBody(String(line)) {
                found.append("\(file.name):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
        return found
    }

    /// Whether `line` declares something with its whole body on it.
    static func isOneLineBody(_ line: String) -> Bool {
        let code = withoutComment(line)
        guard let keyword = keyword(of: code), let span = bodySpan(code) else {
            return false
        }
        let head = String(code[..<span.lowerBound])
        let body = code[code.index(after: span.lowerBound) ..< span.upperBound]
            .trimmingCharacters(in: .whitespaces)
        if body.isEmpty || requirements.contains(body) {
            return false
        }
        if keyword == "var" {
            // A stored property's observers are a body too; its initial value or closure is not.
            if body.hasPrefix("didSet") || body.hasPrefix("willSet") {
                return true
            }
            let outside = head.replacingOccurrences(of: #"\([^()]*\)"#, with: "", options: .regularExpression)
            return !outside.contains("=") && outside.contains(":")
        }
        return true
    }

    /// The declaring keyword after attributes and modifiers; nil for a line that declares nothing with a body.
    private static func keyword(of code: String) -> String? {
        var rest = Substring(code.drop { $0 == " " || $0 == "\t" })
        while true {
            if rest.hasPrefix("@") {
                rest = skipAttribute(rest)
                continue
            }
            let word = rest.prefix { !" {(:<".contains($0) }
            let withSetter = rest.prefix { $0 != " " }
            if modifiers.contains(String(withSetter)) {
                rest = rest.dropFirst(withSetter.count).drop { $0 == " " }
                continue
            }
            if modifiers.contains(String(word)) {
                rest = rest.dropFirst(word.count).drop { $0 == " " }
                continue
            }
            guard keywords.contains(String(word)) else {
                return nil
            }
            // `get:` and `set:` are a call's argument labels, not accessors.
            let after = rest.dropFirst(word.count).drop { $0 == " " }
            return after.hasPrefix(":") ? nil : String(word)
        }
    }

    private static func skipAttribute(_ text: Substring) -> Substring {
        var rest = text.dropFirst().drop { $0.isLetter || $0.isNumber || $0 == "_" }
        if rest.hasPrefix("(") {
            var depth = 0
            while let first = rest.first {
                rest = rest.dropFirst()
                if first == "(" {
                    depth += 1
                } else if first == ")" {
                    depth -= 1
                    if depth == 0 {
                        break
                    }
                }
            }
        }
        return rest.drop { $0 == " " }
    }

    /// The code before a trailing `//` comment, strings respected.
    private static func withoutComment(_ line: String) -> String {
        var inString = false
        var escaped = false
        var previous: Character?
        for index in line.indices {
            let character = line[index]
            if escaped {
                escaped = false
            } else if character == "\\", inString {
                escaped = true
            } else if character == "\"" {
                inString.toggle()
            } else if !inString, character == "/", previous == "/" {
                return String(line[..<line.index(before: index)]).trimmingCharacters(in: .whitespaces)
            }
            previous = character
        }
        return line.trimmingCharacters(in: .whitespaces)
    }

    /// The braces of the block the first `{` outside parentheses opens, when it closes at the line's end.
    private static func bodySpan(_ code: String) -> Range<String.Index>? {
        var depth = 0
        var parentheses = 0
        var inString = false
        var escaped = false
        var start: String.Index?
        for index in code.indices {
            let character = code[index]
            if escaped {
                escaped = false
                continue
            }
            if character == "\\", inString {
                escaped = true
                continue
            }
            if character == "\"" {
                inString.toggle()
                continue
            }
            guard !inString else {
                continue
            }
            switch character {
                case "(", "[": parentheses += 1
                case ")", "]": parentheses -= 1
                case "{":
                    if depth == 0, parentheses == 0, start == nil {
                        start = index
                    }
                    depth += 1
                case "}":
                    depth -= 1
                    if depth == 0, let start {
                        return code.index(after: index) == code.endIndex ? start ..< index : nil
                    }
                default: break
            }
        }
        return nil
    }
}
