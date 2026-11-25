import Foundation
import Testing

@testable import SunsetStorage

/// Bounded, secret-free SIEM audit log (`SecurityAuditLog`, R-OPS-1): enforces `0600` permissions, single-line JSONL
/// sanitization, and round-trip parsing.
@Suite("Security audit log (SIEM JSONL)")
struct SecurityAuditLogTests {
    @Test func `records sanitized single-line 0600 JSONL entries and reads them back`() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "sunset-audit-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appending(path: "security-audit.jsonl")
        let log = SecurityAuditLog(fileURL: file)
        let when = Date(timeIntervalSince1970: 1_700_000_000)

        log.record(
            .update("refused"),
            outcome: "expired\nindex",
            attributes: ["tag": "v0.1.0-alpha.17", "note": String(repeating: "a", count: 300)],
            at: when
        )
        log.record(.vault("unlocked"), outcome: "ok", attributes: ["factor": "password"], at: when)

        let perms = try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? Int
        #expect(perms == 0o600)

        let entries = log.readEntries()
        #expect(entries.count == 2)
        #expect(entries[0].kind == .update("refused"))
        #expect(!entries[0].outcome.contains("\n"))
        #expect((entries[0].attributes["note"]?.count ?? 0) == SecurityAuditLog.maximumAttributeLength)
        #expect(entries[1].kind == .vault("unlocked"))
    }
}
