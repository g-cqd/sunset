import Foundation
import Testing

/// Roadmap 0086 B (ADR-0087): raw tasks, sleeps and reads of the time are counted, and the count only goes down. Lower
/// `remaining` with each migration; it is zero when the stage is done.
@Suite("Tasks and time through the runtime's seams")
struct UnseamedTimeTests {
    /// What is left to move onto `Runtime`.
    static let remaining = 0

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
