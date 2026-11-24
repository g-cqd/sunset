import AemiJSONCore
import AemiTestKit
import Foundation
import OrderedCollections
import Testing

@testable import SunsetCredentials

/// A Bitwarden export that is damaged, or made to look like one, is read or refused and never stops the app (roadmap 0095 E, white paper 9).
/// Two kinds of damage: bytes of the text flipped, inserted and cut; and the document's own nodes replaced, by a value of another type, a huge
/// number, an empty or deep container, the nodes of a valid export one at a time. Whatever is read is entries of the vault's own kinds.
@Suite("Importing Bitwarden's JSON: damaged files")
struct BitwardenImportFuzzTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private var known: Set<UUID?> {
        [EntryTemplate.login.id, EntryTemplate.secureNote.id, EntryTemplate.card.id, EntryTemplate.identity.id]
    }

    /// A valid export of a few dozen items of every kind.
    private var corpus: BitwardenDocument {
        var rng = SeededRNG(seed: Seed.named("bw.fuzz.corpus"))
        var document = BitwardenDocument.generator.generate(using: &rng)
        while document.items.count < 24 {
            document.items += BitwardenDocument.generator.generate(using: &rng).items
        }
        return document
    }

    /// Runs `iterations` mutants of the corpus; returns how many were still read.
    private func fuzz(_ iterations: Int, edits: [ByteMutator.Edit], seed: String) -> Int {
        let base = corpus.bytes
        var read = 0
        let report = fuzzNeverTraps(
            seed: .named(seed),
            iterations: iterations,
            edits: 1 ... 10,
            mutator: ByteMutator(allowedEdits: edits),
            corpus: { base },
            exercise: { bytes in
                guard
                    let imported = try? LoginImport.readBitwarden(
                        String(decoding: bytes, as: UTF8.self),
                        site: self.site
                    )
                else {
                    return
                }
                read += 1
                #expect(imported.entries.allSatisfy { self.known.contains($0.template) })
                #expect(
                    imported.entries.count + imported.skipped.count <= 24 + 60,
                    "a few bytes cannot make many more items"
                )
            }
        )
        #expect(report.iterations == iterations)
        return read
    }

    @Test
    func
        `bytes overwritten and flipped in place: the ones still files are read, and what is read is of the vault's kinds`()
    {
        let read = fuzz(4_000, edits: [.overwrite, .bitFlip], seed: "bw.fuzz.inplace")
        // A strict parser refuses most of them (a control character or a broken escape among up to ten edits), about one in ten gets through (423
        // of 4000 on 2026-11-24): hundreds of damaged files that are still exports. The nodes test below is the one that reaches the mapping.
        #expect(read > 200, "\(read) of 4000 mutants were read")
    }

    @Test func `bytes also cut and appended to: read or refused, never a crash`() {
        _ = fuzz(4_000, edits: ByteMutator.Edit.allCases, seed: "bw.fuzz.bytes")
    }

    @Test func `nodes of the document replaced, one after the other, by a value of another type`() throws {
        let root = corpus.json
        let replacements: [JSONValue] = [
            .null, .bool(true), .bool(false), .int(0), .int(-1), .int(Int64.max), .number(1e308), .number(0.5),
            .string(""),
            .string(String(repeating: "x", count: 100_000)), .string("\u{0}\u{FFFD}"), .array([]),
            .array([.null, .array([])]), .object([:]),
            .object(["type": .int(1), "name": .string("x")])
        ]
        var count = 0
        var rng = SeededRNG(seed: Seed.named("bw.fuzz.nodes"))
        for _ in 0 ..< 3_000 {
            let replacement = replacements[rng.uniform(replacements.count)]
            var mutated = root
            _ = Self.replace(&mutated, at: rng.uniform(1_000_000), with: replacement)
            let text = String(decoding: (try? mutated.encodedBytes()) ?? [], as: UTF8.self)
            if let imported = try? LoginImport.readBitwarden(text, site: site) {
                count += 1
                #expect(imported.entries.allSatisfy { known.contains($0.template) })
            }
        }
        // Most of these are still exports: one node of a hundred changed.
        #expect(count > 2_000, "\(count) of 3000")
    }

    /// Replaces the node whose number in a walk of the tree is `index` modulo its size; returns whether it did.
    static func replace(_ value: inout JSONValue, at index: Int, with replacement: JSONValue) -> Bool {
        var size = 0
        count(value, into: &size)
        var target = index % max(size, 1)
        return replace(&value, target: &target, with: replacement)
    }

    private static func count(_ value: JSONValue, into size: inout Int) {
        size += 1
        switch value {
            case .array(let items): items.forEach { count($0, into: &size) }
            case .object(let object): object.values.forEach { count($0, into: &size) }
            default: break
        }
    }

    private static func replace(_ value: inout JSONValue, target: inout Int, with replacement: JSONValue) -> Bool {
        if target == 0 {
            value = replacement
            return true
        }
        target -= 1
        switch value {
            case .array(var items):
                for index in items.indices where replace(&items[index], target: &target, with: replacement) {
                    value = .array(items)
                    return true
                }
            case .object(var object):
                for key in Array(object.keys) {
                    guard var child = object[key] else { continue }
                    if replace(&child, target: &target, with: replacement) {
                        object[key] = child
                        value = .object(object)
                        return true
                    }
                }
            default: break
        }
        return false
    }

    @Test func `the document cut at every length`() {
        let base = corpus.bytes
        for length in stride(from: 0, to: base.count, by: 11) {
            _ = try? LoginImport.readBitwarden(String(decoding: base[..<length], as: UTF8.self), site: site)
        }
    }

    @Test func `arbitrary bytes, and arbitrary bytes behind a valid beginning`() {
        forAll(Gen.bytes(maxCount: 300), count: 800, seed: .named("bw.fuzz.garbage")) { bytes in
            let text = String(decoding: bytes, as: UTF8.self)
            _ = try? LoginImport.readBitwarden(text, site: self.site)
            _ = try? LoginImport.readBitwarden(#"{"items": ["# + text, site: self.site)
            return true
        }
    }
}
