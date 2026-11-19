import Foundation

/// Raw tasks, sleeps and reads of the time (ADR-0087, the owner's note n55): each goes through `Runtime` (SunsetRuntime) — its
/// `TaskProvider`, its `Clock`, its `now` — so that a test can run the tasks it starts and move the time itself.
enum UnseamedTime {
    static let needles = [
        "Task {", "Task(priority", "Task.detached", "Task.sleep", "ContinuousClock", "Date()"
    ]

    /// The one file that holds the live forms.
    static let seam = "Runtime.swift"

    /// Whether `code` holds `needle` as a word of its own (`group.addTask {` is a task group's, structured).
    static func contains(_ code: String, _ needle: String) -> Bool {
        var rest = code[...]
        while let range = rest.range(of: needle) {
            let before = range.lowerBound == code.startIndex ? nil : code[code.index(before: range.lowerBound)]
            if before.map({ !($0.isLetter || $0.isNumber || $0 == "_" || $0 == ".") }) ?? true {
                return true
            }
            rest = rest[range.upperBound...]
        }
        return false
    }

    /// Each use in `files`, as `file:line: needle`; comments aside.
    static func uses(in files: [(name: String, text: String)]) -> [String] {
        var found: [String] = []
        for file in files where file.name != seam {
            let lines = file.text.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() {
                let code = line.trimmingCharacters(in: .whitespaces)
                guard !code.hasPrefix("//") else {
                    continue
                }
                for needle in needles where contains(code, needle) {
                    found.append("\(file.name):\(index + 1): \(needle)")
                }
            }
        }
        return found
    }
}
