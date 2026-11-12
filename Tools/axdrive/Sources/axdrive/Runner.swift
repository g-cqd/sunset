import Foundation

/// Steps read from stdin, run in one process (no start-up per step): each line is a command without the process id; `#` starts a comment;
/// `sleep S` waits. Stops at the first step that fails, with its line.
enum Runner {
    static func run(pid: pid_t) async -> Int32 {
        var number = 0
        while let line = readLine() {
            number += 1
            let text = line.trimmingCharacters(in: .whitespaces)
            if text.isEmpty || text.hasPrefix("#") { continue }
            let words = split(text)
            if words.first == "sleep" {
                try? await Task.sleep(for: .seconds(Double(words.dropFirst().first ?? "0") ?? 0))
                continue
            }
            let options = Options(["axdrive", words[0], String(pid)] + words.dropFirst())
            guard Guard.allows(pid) else { return Launcher.refused(pid) }
            let status = await Commands.run(options)
            if status != 0 {
                FileHandle.standardError.write(Data("axdrive: step \(number) failed: \(text)\n".utf8))
                return status
            }
        }
        return 0
    }

    /// Words, with "double quotes" keeping spaces.
    static func split(_ line: String) -> [String] {
        var words: [String] = []
        var current = ""
        var quoted = false
        for character in line {
            if character == "\"" {
                quoted.toggle()
            } else if character == " ", !quoted {
                if !current.isEmpty { words.append(current) }
                current = ""
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { words.append(current) }
        return words
    }
}
