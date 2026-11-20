import Foundation
import SunsetTestSupport
import Testing

/// Roadmap 0086 E (ADR-0087 rule 5): no new duplicated code. dolly runs over Sources; the number of clones it finds may not
/// rise above `remaining`, which is lowered as they are merged. A count, not a list of fingerprints: dolly's fingerprints change
/// when the code around a clone moves, so a list failed on clones that were there before (seen 2026-11-19). Where dolly is not
/// installed the test says so and passes.
@Suite("No new clones")
struct CloneRatchetTests {
    /// The clones left (2026-11-19: 215 at the start of roadmap 0086 E).
    static let remaining = 151

    private static let dolly = [
        "/Users/\(NSUserName())/.local/bin/dolly", "/opt/homebrew/bin/dolly", "/usr/local/bin/dolly"
    ]
    .first { FileManager.default.isExecutableFile(atPath: $0) }

    @Test func `dolly finds no more clones than are left`() throws {
        guard let dolly = Self.dolly else {
            print("dolly is not installed: the clone ratchet is not checked here")
            return
        }
        let root = RepositoryFiles.root
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dolly)
        process.currentDirectoryURL = root
        process.arguments = ["analyze", "Sources", "--format", "json"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let found = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let findings = found?["findings"] as? [[String: Any]] ?? []
        #expect(
            findings.count <= Self.remaining,
            "\(findings.count) clones, \(Self.remaining) allowed: merge the new one (dolly analyze Sources)"
        )
        if findings.count < Self.remaining {
            print("fewer clones than allowed (\(findings.count)): lower `remaining` to it")
        }
    }
}
