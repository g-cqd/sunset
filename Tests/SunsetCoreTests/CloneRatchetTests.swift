import Foundation
import SunsetTestSupport
import Testing

/// Roadmap 0086 E (ADR-0087 rule 5): no new duplicated code. dolly runs over Sources with the baseline of what is left
/// (`Scripts/quality/clones-baseline.json`); a finding outside it fails. Where dolly is not installed the test says so and
/// passes: the baseline is the record, and a machine with dolly holds it.
@Suite("No new clones")
struct CloneRatchetTests {
    private static let dolly = [
        "/Users/\(NSUserName())/.local/bin/dolly", "/opt/homebrew/bin/dolly", "/usr/local/bin/dolly"
    ]
    .first { FileManager.default.isExecutableFile(atPath: $0) }

    @Test func `dolly finds nothing outside the baseline`() throws {
        guard let dolly = Self.dolly else {
            print("dolly is not installed: the clone ratchet is not checked here")
            return
        }
        let root = RepositoryFiles.root
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dolly)
        process.currentDirectoryURL = root
        process.arguments = [
            "analyze", "Sources", "--baseline", "Scripts/quality/clones-baseline.json", "--format", "json"
        ]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let found = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let findings = found?["findings"] as? [[String: Any]] ?? []
        let places = findings.map { finding in
            "\((finding["path"] as? String ?? "").replacingOccurrences(of: root.path + "/", with: "")):\(finding["line"] ?? 0)"
        }
        #expect(
            findings.isEmpty,
            "\(findings.count) new clones: \(places.prefix(6)); merge them, they are code that says one thing"
        )
    }
}
