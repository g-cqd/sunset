import Foundation
import SunsetTestSupport
import Testing

/// Roadmap 0086 B (ADR-0087): raw tasks, sleeps and reads of the time are counted, and the count only goes down. Lower
/// `remaining` with each migration; it is zero when the stage is done.
@Suite("Tasks and time through the runtime's seams")
struct UnseamedTimeTests {
    /// What is left to move onto `Runtime`.
    static let remaining = 0

    @Test func `no test sleeps or reads the time but through SunsetTestSupport`() {
        let files = RepositoryFiles.swiftFiles(in: ["Tests"])
            .filter { !$0.name.hasPrefix("UnseamedTime") && !Self.support.contains($0.name) }
        let uses = UnseamedTime.uses(in: files).filter { !$0.hasSuffix(": Task {") }
        #expect(uses.isEmpty, "\(uses.count): \(uses.prefix(8).joined(separator: "\n"))")
    }

    /// The test support's own files: the one place a test's real time and test clock are made.
    static let support: Set<String> = ["TestTime.swift", "RealWait.swift", "Stopwatch.swift"]

    @Test func `raw tasks, sleeps and reads of the time in Sources are exactly what is left to move`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources"])
        #expect(files.count > 50, "the scan must see the repository: \(files.count) files")
        let uses = UnseamedTime.uses(in: files)
        #expect(
            uses.count == Self.remaining,
            "\(uses.count) raw uses, \(Self.remaining) allowed: move the new ones onto Runtime, or lower the count"
        )
    }
}
