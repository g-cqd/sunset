import AemiTestKit
import Foundation
import Testing

@testable import SunsetCredentials

/// A file that is not what it says it is must not stop the app (roadmap 0095 D, white paper 9: what a program, a file or a page hands
/// Sunset is untrusted): an export mutated byte by byte, thousands of times, is read or refused, never trapped on, and what it yields is
/// always logins of the vault's own Login template, never more than the file has rows.
@Suite("Importing logins: mutated files")
struct LoginImportFuzzTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    /// An export of a few dozen logins that use the awkward characters.
    private func corpus() -> [UInt8] {
        var rng = SeededRNG(seed: Seed.named("login.fuzz.corpus"))
        let text = Gen.string(maxLength: 12, alphabet: LoginRoundTripTests.alphabet)
        var entries: [VaultEntry] = []
        for index in 0 ..< 40 {
            var entry = EntryTemplate.login.makeEntry(title: "Site \(index) " + text.generate(using: &rng))
            for (name, value) in [
                ("Website", "https://site\(index).example.com/login"), ("Username", text.generate(using: &rng)),
                ("Password", text.generate(using: &rng) + "x")
            ] {
                if let field = entry.field(named: name)?.id { entry.set(field, value) }
            }
            entry.note = text.generate(using: &rng)
            entries.append(entry)
        }
        return Array(LoginExport.csv(of: entries).text.utf8)
    }

    @Test func `a mutated export is read or refused, and what is read is only logins`() {
        let base = corpus()
        let baseRows = CSVReader.rows(String(decoding: base, as: UTF8.self)).count
        var read = 0
        let report = fuzzNeverTraps(
            seed: .named("login.fuzz"),
            iterations: 4_000,
            edits: 1 ... 12,
            corpus: { base },
            exercise: { bytes in
                let text = String(decoding: bytes, as: UTF8.self)
                guard let imported = try? LoginImport.read(text, site: self.site) else { return }
                read += 1
                #expect(imported.entries.allSatisfy { $0.template == EntryTemplate.login.id })
                #expect(imported.entries.count + imported.skipped.count <= CSVReader.rows(text).count)
                // A byte flipped in a few cells cannot make a file of 40 logins into many more.
                #expect(imported.entries.count <= baseRows + 12)
            }
        )
        #expect(report.iterations == 4_000)
        // Not vacuous: most mutants are still files of logins (a flipped byte rarely removes the password column).
        #expect(read > 2_000, "\(read) of 4000 mutants were read")
    }

    @Test func `a file cut at every length is read or refused`() {
        let base = corpus()
        for length in stride(from: 0, to: base.count, by: 7) {
            let text = String(decoding: base[..<length], as: UTF8.self)
            _ = try? LoginImport.read(text, site: site)
        }
    }

    @Test func `arbitrary bytes are read or refused`() {
        forAll(Gen.bytes(maxCount: 400), count: 800, seed: .named("login.bytes")) { bytes in
            let text = String(decoding: bytes, as: UTF8.self)
            _ = try? LoginImport.read(text, site: self.site)
            return true
        }
    }
}
