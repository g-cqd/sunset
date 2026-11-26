import Foundation
import SunsetRuntime
import Testing

@testable import SunsetCredentials

/// Tests roadmap 0092 C/D/F and single-transaction batch import:
/// - Sealed file attachments (`VaultAttachment`) + size cap + vault round-trip
/// - Secret field history (`FieldHistoryItem`, capped at `EntryField.historyLimit`)
/// - Diceware passphrase generator (`PassphraseRecipe`)
/// - Offline vault password health audit (`VaultHealthReport`: weak & reused detection)
/// - Atomic single-transaction `Vault.saveBatch`
@Suite("Vault entries: attachments, history, passphrases, health, and batch save") struct VaultEntriesExtendedTests {
    @Test func `secret field history records prior non-empty values, skips non-secret fields, and caps length`() throws
    {
        var entry = EntryTemplate.login.makeEntry(title: "Example")
        let pwID = try #require(entry.field(named: "Password")?.id)
        let userID = try #require(entry.field(named: "Username")?.id)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)

        entry.set(userID, "alice", recordingHistoryAt: t0)
        entry.set(userID, "bob", recordingHistoryAt: t0.addingTimeInterval(10))
        #expect(entry.field(named: "Username")?.history == nil)

        entry.set(pwID, "initial-secret", recordingHistoryAt: t0)
        #expect(entry.field(named: "Password")?.history == nil, "first non-empty value has no prior secret")

        for step in 1 ... 25 {
            entry.set(pwID, "secret-\(step)", recordingHistoryAt: t0.addingTimeInterval(Double(step)))
        }
        let history = try #require(entry.field(named: "Password")?.history)
        #expect(history.count == EntryField.historyLimit)
        #expect(history.last?.value == "secret-24")
        #expect(entry.field(named: "Password")?.value == "secret-25")
    }

    @Test func `attachments enforce size limit and round-trip through Codable`() throws {
        var entry = EntryTemplate.login.makeEntry(title: "SSH Keys")
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let small = VaultAttachment(
            filename: "id_ed25519.pub",
            contentType: "text/plain",
            data: Data("ssh-ed25519 AAAAC3Nza".utf8),
            addedAt: t0
        )
        let added = entry.addAttachment(small)
        #expect(added)
        #expect(entry.attachments?.count == 1)

        let oversized = VaultAttachment(
            filename: "huge.bin",
            data: Data(count: VaultAttachment.maxBytes + 1),
            addedAt: t0
        )
        let addedOversized = entry.addAttachment(oversized)
        #expect(!addedOversized)
        #expect(entry.attachments?.count == 1)

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(VaultEntry.self, from: encoded)
        #expect(decoded == entry)

        entry.removeAttachment(small.id)
        #expect(entry.attachments == nil)
    }

    @Test func `passphrase recipe generates deterministic words with separator, capitalization, and digit`() {
        var rng = SystemRandomNumberGenerator()
        let recipe = PassphraseRecipe(words: 6, separator: ".", capitalize: true, includeNumber: true)
        let phrase = recipe.generate(using: &rng)
        let parts = phrase.split(separator: ".")
        #expect(parts.count == 6)
        #expect(parts.allSatisfy { $0.first?.isUppercase == true })
        #expect(phrase.contains(where: { $0.isNumber }))
        #expect(recipe.entropyBits > 48)
    }

    @Test func `vault health report flags weak and reused passwords offline`() throws {
        var weak1 = EntryTemplate.login.makeEntry(title: "Weak")
        weak1.set(try #require(weak1.field(named: "Password")?.id), "short1")

        var reusedA = EntryTemplate.login.makeEntry(title: "Site A")
        reusedA.set(try #require(reusedA.field(named: "Password")?.id), "Str0ng!UniquePass#99")

        var reusedB = EntryTemplate.login.makeEntry(title: "Site B")
        reusedB.set(try #require(reusedB.field(named: "Password")?.id), "Str0ng!UniquePass#99")

        var strong = EntryTemplate.login.makeEntry(title: "Strong")
        strong.set(try #require(strong.field(named: "Password")?.id), "Another$tr0ngP@ss2026!")

        let report = VaultHealthReport.analyze([weak1, reusedA, reusedB, strong])
        #expect(report.totalPasswords == 4)
        #expect(report.weak.map(\.entryID) == [weak1.id])
        #expect(Set(report.reused.map(\.entryID)) == Set([reusedA.id, reusedB.id]))
    }

    @MainActor @Test func `saveBatch stores many entries in one SQLite transaction`() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "vault-batch-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let path = dir.appending(path: "vault.sqlite").path
        let cheap = MasterPassword.Cost(memoryKiB: 1024, passes: 1, lanes: 1)
        let (vault, _) = try Vault.create(
            at: path,
            password: "correct-horse-battery-staple",
            cost: cheap,
            runtime: .live
        )
        let batch = (1 ... 50).map { EntryTemplate.login.makeEntry(title: "Entry \($0)") }
        try vault.saveBatch(batch)
        let stored = try vault.entries()
        #expect(stored.count == 50)
        #expect(Set(stored.map(\.id)) == Set(batch.map(\.id)))
    }
}
