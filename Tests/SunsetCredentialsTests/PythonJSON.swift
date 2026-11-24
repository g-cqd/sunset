import AemiJSON
import Foundation

/// Python's `json` module, run as a process (an oracle, never linked): a JSON text written back the way Python writes it, in the forms it
/// has: ASCII only with every non-ASCII character as `\uXXXX` (surrogate pairs for the astral ones), UTF-8 as it is, and indented with its keys
/// sorted. A reader of JSON reads each of them as the same document. The texts travel as a JSON array of strings, by AemiJSON.
enum PythonJSON {
    private static let script = """
        import sys, json
        out = []
        for text in json.load(sys.stdin):
            document = json.loads(text)
            out.append([
                json.dumps(document, ensure_ascii=True),
                json.dumps(document, ensure_ascii=False),
                json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True),
                json.dumps(document, ensure_ascii=True, separators=(",", ":")),
            ])
        json.dump(out, sys.stdout, ensure_ascii=False)
        """

    /// For each text, its four forms; nil when Python is not there or fails.
    static func forms(of texts: [String]) -> [[String]]? {
        guard let path = PythonCSV.path, let input = try? AemiJSON.JSONEncoder().encode(texts) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["-c", script]
        let (stdin, stdout) = (Pipe(), Pipe())
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        let writer = Thread {
            stdin.fileHandleForWriting.write(input)
            try? stdin.fileHandleForWriting.close()
        }
        writer.start()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return try? AemiJSON.JSONDecoder().decode([[String]].self, from: output)
    }
}
