import AemiJSON
import Foundation

/// Python's csv module, run as a process: tables in as JSON on its input, tables or texts out as JSON.
enum PythonCSV {
    static let path: String? = ["/usr/bin/python3", "/opt/homebrew/bin/python3", "/usr/local/bin/python3"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }

    private static let script = """
        import sys, json, csv, io
        mode, data = sys.argv[1], json.load(sys.stdin)
        out = []
        if mode == "write":
            for table in data:
                buffer = io.StringIO()
                writer = csv.writer(buffer, lineterminator="\\r\\n")
                for row in table: writer.writerow(row)
                out.append(buffer.getvalue())
        else:
            for text in data:
                out.append([row for row in csv.reader(io.StringIO(text, newline="")) if row])
        json.dump(out, sys.stdout, ensure_ascii=False)
        """

    static func write(_ tables: [[[String]]]) -> [String]? {
        run("write", input: tables)
    }

    static func read(_ texts: [String]) -> [[[String]]]? {
        run("read", input: texts)
    }

    private static func run<Input: Encodable, Output: Decodable>(_ mode: String, input: Input) -> Output? {
        guard let path, let data = try? AemiJSON.JSONEncoder().encode(input) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["-c", script, mode]
        let (stdin, stdout) = (Pipe(), Pipe())
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        // The input is written from another thread so that a large one cannot fill the pipe while the output waits to be read.
        let writer = Thread {
            stdin.fileHandleForWriting.write(data)
            try? stdin.fileHandleForWriting.close()
        }
        writer.start()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return try? AemiJSON.JSONDecoder().decode(Output.self, from: output)
    }
}
