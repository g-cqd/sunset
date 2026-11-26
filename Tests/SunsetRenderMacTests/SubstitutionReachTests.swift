import AemiTestKit
import CoreText
import Foundation
import Testing

@testable import SunsetRenderMac

/// What the substitution reach (t241) keeps, on tables built to the specs (`GSUBTableBuilder`, and a `morx` here):
/// a glyph a rule could change in a run of kept glyphs is let go, the rest kept; features off unless asked are not
/// counted; a feature variation's alternates are; a table that does not read leaves nothing, and never traps.
@Suite("Substitution reach: which glyphs shaping cannot change") struct SubstitutionReachTests {
    typealias B = GSUBTableBuilder
    /// Glyphs 10 to 19 stand for letters, 20 to 29 for punctuation.
    static let letters = Set<UInt16>(10 ... 19)
    static let glyphs = Set<UInt16>(10 ... 29)

    private func kept(_ builder: B, settings: [FontFeature] = [], within glyphs: Set<UInt16> = glyphs) throws -> Set<
        UInt16
    > {
        let reach = try GSUBReach(builder.bytes()) { SubstitutionReach.isApplied($0, settings: settings) }
        return try SubstitutionReach.unchanged(glyphs, tables: [reach]) { removed in
            removed.reduce(0) { $0 + (Self.letters.contains($1) ? 64 : 1) }
        }
    }

    @Test func `a ligature lets go one of its glyphs, the punctuation before a letter`() throws {
        let arrow = B(features: [("liga", [0])], lookups: [(4, [B.ligature([20, 21], into: 99)])])
        #expect(try kept(arrow) == Self.glyphs.subtracting([20]))
        let word = B(features: [("liga", [0])], lookups: [(4, [B.ligature([10, 22], into: 99)])])
        #expect(try kept(word) == Self.glyphs.subtracting([22]))
        let outside = B(features: [("liga", [0])], lookups: [(4, [B.ligature([20, 40], into: 99)])])
        #expect(try kept(outside) == Self.glyphs, "a ligature with a glyph no run has never forms")
    }

    @Test func `features off unless asked, or turned off, are not counted`() throws {
        let lookups: [(type: Int, subtables: [[UInt8]])] = [(4, [B.ligature([20, 21], into: 99)])]
        for tag in ["dlig", "ss01", "cv12", "zero", "aalt", "salt", "case"] {
            #expect(try kept(B(features: [(tag, [0])], lookups: lookups)) == Self.glyphs, "\(tag)")
            #expect(try kept(B(features: [(tag, [0])], lookups: lookups), settings: [FontFeature(tag, 1)]).count == 19)
        }
        for tag in ["liga", "clig", "calt"] {
            #expect(
                try kept(B(features: [(tag, [0])], lookups: lookups), settings: [FontFeature(tag, 0)]) == Self.glyphs
            )
        }
        for tag in ["locl", "ccmp", "rlig", "rclt", "xyzw"] {
            #expect(
                try kept(B(features: [(tag, [0])], lookups: lookups), settings: [FontFeature(tag, 0)]).count == 19,
                "\(tag)"
            )
        }
    }

    @Test func `a single substitution to the same glyph changes nothing`() throws {
        let same = B(features: [("locl", [0])], lookups: [(1, [B.single([(12, 12), (23, 23)])])])
        #expect(try kept(same) == Self.glyphs)
        let other = B(features: [("locl", [0])], lookups: [(1, [B.single([(12, 12), (23, 80)])])])
        #expect(try kept(other) == Self.glyphs.subtracting([23]))
    }

    @Test func `a chained rule fires only with every position and a change at its record`() throws {
        // The rule "20 then 11, before 21" changes 11 through lookup 1.
        func rule(_ substitutions: [(Int, Int)], lookahead: [Int] = [21]) -> B {
            let chain = B.chained(backtrack: [[20]], input: [[11]], lookahead: [lookahead], records: [(0, 1)])
            return B(features: [("calt", [0])], lookups: [(6, [chain]), (1, [B.single(substitutions)])])
        }
        let fires = try kept(rule([(11, 90)]))
        #expect(fires.count == 19 && fires.isSuperset(of: Self.letters), "\(fires.sorted())")
        #expect(try kept(rule([(12, 90)])) == Self.glyphs, "its lookup changes another glyph")
        #expect(try kept(rule([(11, 11)])) == Self.glyphs, "its lookup changes nothing")
        #expect(try kept(rule([(11, 90)], lookahead: [41])) == Self.glyphs, "a position no run fills")
        #expect(try kept(rule([(11, 90)]), within: Self.glyphs.subtracting([21])) == Self.glyphs.subtracting([21]))
    }

    @Test func `a feature variation's alternate lookups count`() throws {
        var builder = B(features: [("calt", []), ("dlig", [])], lookups: [(4, [B.ligature([24, 25], into: 99)])])
        #expect(try kept(builder) == Self.glyphs)
        builder.alternates = [(0, [0])]
        #expect(try kept(builder) == Self.glyphs.subtracting([24]))
        builder.alternates = [(1, [0])]
        #expect(try kept(builder) == Self.glyphs, "an alternate of a feature not applied")
    }

    /// A `morx` with one chain (default flags 1) of one noncontextual subtable, lookup format 8 from glyph 10.
    static func morx(flags: Int, values: [Int]) -> [UInt8] {
        let lookup = B.u16(8) + B.u16(10) + B.u16(values.count) + values.flatMap(B.u16)
        let subtable = B.u32(12 + lookup.count) + B.u32(4) + B.u32(flags) + lookup
        return B.u16(2) + B.u16(0) + B.u32(1) + B.u32(1) + B.u32(16 + subtable.count) + B.u32(0) + B.u32(1) + subtable
    }

    @Test func `a morx glyph substitution lets go what it changes, when its chain has it on`() throws {
        let values = Array(10 ... 29).map { $0 == 15 ? 77 : $0 }
        let on = try MorxReach(Self.morx(flags: 1, values: values))
        #expect(
            try SubstitutionReach.unchanged(Self.glyphs, tables: [on]) { $0.count } == Self.glyphs.subtracting([15])
        )
        let off = try MorxReach(Self.morx(flags: 2, values: values))
        #expect(try SubstitutionReach.unchanged(Self.glyphs, tables: [off]) { $0.count } == Self.glyphs)
    }

    /// Menlo's `morx` (state tables: its `fi` and `fl` ligatures) and a built `GSUB`, cut short at every length and
    /// with bytes changed at random: each reads, or is malformed; none traps, and what is kept is never more.
    @Test func `tables cut short or changed never trap`() throws {
        let menlo = CTFontCreateWithName("Menlo" as CFString, 12, nil)
        let morx = try #require(CTFontCopyTable(menlo, CTFontTableTag(kCTFontTableMorx), []) as Data?)
        let chain = B.chained(backtrack: [[20]], input: [[11]], lookahead: [[21]], records: [(0, 1)])
        let gsub = B(
            features: [("calt", [0]), ("liga", [2])],
            lookups: [(6, [chain]), (1, [B.single([(11, 90)])]), (4, [B.ligature([20, 21, 22], into: 99)])],
            alternates: [(1, [1])]
        )
        .bytes()
        var rng = SeededRNG(seed: 0x241)
        for (name, bytes) in [("morx", [UInt8](morx)), ("GSUB", gsub)] {
            func reach(_ bytes: [UInt8]) -> Set<UInt16>? {
                let table: (any SubstitutionTable)?
                if name == "morx" { table = try? MorxReach(bytes) } else { table = try? GSUBReach(bytes) { _ in true } }
                guard let table else { return nil }
                return try? SubstitutionReach.unchanged(Self.glyphs, tables: [table]) { $0.count }
            }
            #expect(reach(bytes) != nil, "\(name) reads whole")
            for length in stride(from: 0, to: bytes.count, by: max(1, bytes.count / 2_000)) {
                #expect(reach(Array(bytes.prefix(length)))?.isSubset(of: Self.glyphs) ?? true)
            }
            for _ in 0 ..< 3_000 {
                var changed = bytes
                for _ in 0 ... rng.next() % 4 {
                    changed[Int(rng.next() % UInt64(changed.count))] = UInt8(truncatingIfNeeded: rng.next())
                }
                #expect(reach(changed)?.isSubset(of: Self.glyphs) ?? true)
            }
        }
    }
}
