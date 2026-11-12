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
                evidence(pid: pid, step: number)
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

    /// What the app showed when a step failed: a picture and the tree, in the test's own folder.
    static func evidence(pid: pid_t, step: Int) {
        guard let config = Guard.environment(of: pid)?["SUNSET_CONFIG"] else { return }
        let folder = (config as NSString).deletingLastPathComponent
        let picture = folder + "/failed-step-\(step).png"
        _ = Capture.shot(pid: pid, to: picture, window: nil)
        let tree = Tree.nodes(pid: pid, windowFilter: nil, includeMenus: false)
            .map {
                String(repeating: "  ", count: max($0.path.split(separator: "/").count - 1, 0)) + $0.summary
            }
        try? tree.joined(separator: "\n")
            .write(toFile: folder + "/failed-step-\(step).txt", atomically: true, encoding: .utf8)
        FileHandle.standardError.write(Data("axdrive: evidence in \(picture) and failed-step-\(step).txt\n".utf8))
    }
}
