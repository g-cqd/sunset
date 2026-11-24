import AemiJSON
import AemiTestKit
import Foundation
import Testing

@testable import SunsetCredentials

/// Any export of Bitwarden's is imported as what it says (roadmap 0095 E): generated exports of all four kinds with every awkward character,
/// written by AemiJSON, and again by Python's `json` in the forms it has (escaped ASCII, UTF-8, indented, compact). What each becomes is worked out
/// from the model in `BitwardenDocument`, not by the importer.
@Suite("Bitwarden's JSON: any export, imported")
struct BitwardenImportPropertyTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    /// Whether `entries` are what `document` says, in order.
    private func imports(_ text: String, as document: BitwardenDocument) -> Bool {
        guard let imported = try? LoginImport.readBitwarden(text, site: site), imported.skipped.isEmpty,
            imported.warnings.isEmpty
        else {
            return false
        }
        let expected = document.expected
        guard imported.entries.count == expected.count else { return false }
        return zip(imported.entries, expected)
            .allSatisfy { entry, want in
                entry.template == want.template && entry.title == want.title && entry.folder == want.folder
                    && entry.isFavorite == want.favorite && entry.note == want.note
                    && want.fields.allSatisfy { name, value in (entry.field(named: name)?.value ?? "") == value }
            }
    }

    @Test func `the documents the tests build are exports, by the schema`() throws {
        let schema = try JSONSchema(parsing: BitwardenSchema.text)
        forAll(BitwardenDocument.generator, count: 300, seed: .named("bw.schema")) { document in
            let result = try? schema.validate(Data(document.bytes))
            return result?.isValid == true
        }
    }

    @Test
    func `the schema refuses what is not an export: an item with no kind, a login with no login, an unknown type`()
        throws
    {
        let schema = try JSONSchema(parsing: BitwardenSchema.text)
        for bad in [
            #"{"items": [{"name": "x"}]}"#, #"{"items": [{"type": 1, "name": "x"}]}"#,
            #"{"items": [{"type": 7, "name": "x"}]}"#,
            #"{"folders": []}"#, #"{"items": "no"}"#, #"[1]"#
        ] {
            #expect((try? schema.validate(Data(bad.utf8)))?.isValid == false, "\(bad)")
        }
    }

    @Test func `written by AemiJSON, every export is imported as what it says`() {
        forAll(BitwardenDocument.generator, count: 400, seed: .named("bw.roundtrip")) { document in
            self.imports(document.text, as: document)
        }
    }

    @Test(.enabled(if: PythonCSV.path != nil))
    func `written by Python's json in each of its forms, the same`() {
        let batches = Gen.array(of: BitwardenDocument.generator, maxCount: 15)
        forAll(batches, count: 12, seed: .named("bw.python")) { documents in
            guard let forms = PythonJSON.forms(of: documents.map(\.text)), forms.count == documents.count else {
                return false
            }
            return zip(documents, forms)
                .allSatisfy { document, variants in
                    variants.count == 4 && variants.allSatisfy { self.imports($0, as: document) }
                }
        }
    }

    @Test func `the same export imported twice adds nothing the second time`() {
        forAll(BitwardenDocument.generator, count: 200, seed: .named("bw.twice")) { document in
            guard
                let first = try? LoginImport.readBitwarden(document.text, site: self.site)
                    .leavingOut(held: [], site: self.site),
                let second = try? LoginImport.readBitwarden(document.text, site: self.site)
                    .leavingOut(held: first.entries, site: self.site)
            else { return false }
            // Two items that are the same in everything but their id are one entry: what was kept is what is not added again.
            return second.entries.isEmpty && first.entries.count + first.duplicates == document.items.count
        }
    }
}
